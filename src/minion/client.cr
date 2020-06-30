require "./client/version"
require "./io_details"
require "./frame"
require "socket"
require "msgpack"
require "retriable"

module Minion
  #####
  # Client Protocol
  #
  #   Length     Payload
  # +--------+=============+
  # |  0xVV  | Packed Data |
  # +--------+=============+
  #
  # The length of packed data should precede the packed data payload. This permits more efficient reading
  # and handling of the stream of data.
  #
  # The Packed Data payload is an array of information that is serialized MessagePack. It is structured
  # as follows:
  #
  # +--------+------+========+========+========+
  # |  Verb  | UUID | Data_1 | Data_2 | Data_n |
  # +--------+------+========+========+========+
  #
  # UUID encodes a timestamp as an unsigned 64 bit integer containing the number of nanoseconds since
  # the Unix epoch, followed by 6 bytes that contain an address or ID of the machine that sent the message,
  # and 2 currently undefined bytes. The ID may be the MAC address or any other 6 byte identifier.
  #
  # The Verb indicates the kind of action to be performed with the data that follows.
  #
  # The data is zero or more additional elements which will be used according to the verb that was given.

  class Client
    class FailedToAuthenticate < Exception
      def initialize(destination = "UNK", port = 6766)
        super("Failed to authenticate to the Minion server at #{destination}:#{port}")
      end
    end

    MAX_MESSAGE_LENGTH          = 8192
    MAX_LENGTH_BYTES            = MAX_MESSAGE_LENGTH.to_s.length
    CONNECTION_FAILURE_TIMEOUT  = 86_400 * 2     # Log locally for a long time if Minion server goes down.
    MAX_FAILURE_COUNT           = 0_u128 &- 1    # Max integer -- i.e. really big
    PERSISTENT_QUEUE_LIMIT      = 10_737_412_742 # Default to allowing around 10GB temporary local log storage
    RECONNECT_THROTTLE_INTERVAL = 0.1

    def send(
      verb : String | Symbol = "",
      uuid : UUID = UUID.new,
      data : Array(String) = [@group, @server] of String
    )
      if @destination == :local
        @local_queue.send({verb, uuid, [@group, @server] + data})
      else
        @remote_queue.send({verb, uuid, [@group, @server] + data})
      end
    # rescue Exception
    #   @authenticated = false
    #   setup_local_logging
    #   setup_reconnect_fiber
    end

    # ----- Various class accessors -- use these to set defaults

    @@connection_failure_timeout : Int32 = CONNECTION_FAILURE_TIMEOUT

    def self.connection_failure_timeout
      @@connection_failure_timeout
    end

    def self.connection_failure_timeout=(val)
      @@connection_failure_timeout = val.to_i
    end

    @@max_failure_count : UInt128 = MAX_FAILURE_COUNT

    def self.max_failure_count
      @@max_failure_count
    end

    def self.max_failure_count=(val)
      @@max_failure_count = val.to_i
    end

    @@persistent_queue_limit = PERSISTENT_QUEUE_LIMIT

    def self.persistent_queue_limit
      @@persistent_queue_limit ||= PERSISTENT_QUEUE_LIMIT
    end

    def self.persistent_queue_limit=(val)
      @@persistent_queue_limit = val.to_i
    end

    def self.reconnect_throttle_interval
      @@reconnect_throttle_interval ||= RECONNECT_THROTTLE_INTERVAL
    end

    def self.reconnect_throttle_interval=(val)
      @@reconnect_throttle_interval = val.to_i
    end

    # -----

    # Instance Variable type declarations
    @socket : TCPSocket?
    @swamp_drainer : Fiber?
    @reconnection_fiber : Fiber?
    @failed_at : Time?
    @connection_failure_timeout : Int32
    @max_failure_count : UInt128
    @persistent_queue_limit : Int64
    # @message_buffer : Slice(UInt8)
    @tmplog : String?
    @reconnect_throttle_interval : Float64
    @io_details : Hash(IO, IoDetails) = {} of IO => IoDetails
    @server : String
    @remote_fiber : Fiber
    @local_fiber : Fiber
    def initialize(
      @host = "127.0.0.1",
      @port = 6766,
      @group = "",
      @server = UUID.new(identifier: build_identifier).to_s,
      @key = "",
      fail_immediately = false
    )
      # That's a lot of instance variables....
      @remote_queue = Channel(Tuple(String|Symbol, UUID|String, Array(String))|Slice(UInt8)).new(100)
      @local_queue = Channel(Tuple(String|Symbol, UUID|String, Array(String))|Slice(UInt8)).new(100)

      @socket = nil
      klass = self.class
      @connection_failure_timeout = klass.connection_failure_timeout
      @max_failure_count = klass.max_failure_count
      @persistent_queue_limit = klass.persistent_queue_limit
      @reconnect_throttle_interval = klass.reconnect_throttle_interval
      @destination = :remote
      @reconnection_fiber = nil
      @authenticated = false
      @total_count = 0
      @logfile = nil
      @swamp_drainer = nil
      @failed_at = nil

      # Establish the initial connection.
      clear_failure
      @remote_fiber, @local_fiber = establish_fibers
      connect(fail_immediately)

      # Tell the user we're authenticated
      if @authenticated == true
        puts "Minion Agent Authenticated!"
      end
    end

    # ----- Various instance accessors

    getter total_count
    getter connection_failure_timeout

    def connection_failure_timeout=(val)
      @connection_failure_timeout = val.to_i
    end

    getter max_failure_count

    def max_failure_count=(val)
      @max_failure_count = val.to_i
    end

    getter ram_queue_limit

    def ram_queue_limit=(val)
      @ram_queue_limit = val.to_i
    end

    getter persistent_queue_limit

    def persistent_queue_limit=(val)
      @persistent_queue_limit = val.to_i
    end

    # Files for temporary storage of log data follow a specific naming pattern

    def tmplog_prefix
      File.join(Dir.tempdir, "minion-SERVICE-PID.log")
    end

    def tmplog
      @tmplog ||= tmplog_prefix.gsub(/SERVICE/, @group).gsub(/PID/, Process.pid.to_s)
    end

    def tmplogs
      Dir[tmplog_prefix.gsub(/SERVICE/, @group).gsub(/PID/, "*")].sort_by { |f| File.info(f).modification_time }
    end

    setter tmplog

    def reconnect_throttle_interval
      @reconnect_throttle_interval ||= self.class.reconnect_throttle_interval
    end

    def reconnect_throttle_interval=(val)
      @reconnect_throttle_interval = val.to_i
    end

    # ----- The meat of the client

    def establish_fibers : Array(Fiber)
      remote_fiber = spawn(name: "remote_send") do
        loop do
          while msg = @remote_queue.receive?
            if msg.is_a?(Slice)
              _send_remote(already_packed_msg: msg)
            else
              _send_remote(verb: msg[0], uuid: msg[1], data: msg[2])
            end
          end
        end
      end

      local_fiber = spawn(name: "local_send") do
        loop do
          while msg = @local_queue.receive?
            if msg.is_a?(Slice)
              _local_log(already_packed_msg: msg)
            else
              _local_log(verb: msg[0], uuid: msg[1], data: msg[2])
            end
          end
        end
      end

      [remote_fiber, local_fiber]
    end

    def connect(fail_immediately = false)
      @socket = open_connection(@host, @port)
      @io_details[@socket.not_nil!] = IoDetails.new
      authenticate
      raise FailedToAuthenticate.new(@host, @port) unless authenticated?

      clear_failure

      if there_is_a_swamp?
        drain_the_swamp
      else
        setup_remote
      end
    rescue e : Exception
      if fail_immediately == true
        raise e
      end

      STDERR.puts e
      STDERR.puts e.backtrace.inspect
      register_failure
      close_connection
      setup_reconnect_fiber unless @reconnection_fiber && !@reconnection_fiber.not_nil!.dead?
      setup_local_logging
      raise e if fail_connect?
    end

    # Read a message from the wire using a length header before the msgpack payload.
    # This code makes every effort to be efficient with both memory and to be robust
    # in the case of partial delivery of expected data.
    #
    # It utilizes a couple of pre-declared buffers in memory to process reads. One is
    # a two byte buffer that is used to read the size of the messagepack frame. The
    # second is an 8k frame that will hold the messagepack struture itself.
    #
    # The code is re-entrant, so if either the size read or the data read is
    # incomplete, it will yield the fiber, allowing another to run, and resume read
    # activities when the fiber is re-entered.

    def read(io = @socket)
      details = @io_details[io]
      if details.read_message_size
        if details.size_read == 0_u16
          details.size_read = @socket.not_nil!.read(details.send_size_buffer).to_u16
          if details.size_read < 2_u16
            Fiber.yield
          end
        end

        if details.size_read == 1_u16
          byte = @socket.not_nil!.read_byte
          if byte
            details.send_size_buffer[1] = byte
            details.size_read = 2_u16
          end
        end

        if details.size_read > 1_u16
          details.read_message_body = true
          details.read_message_size = false
          details.size_read = 0_u16
        end
      end

      if details.read_message_body
        if details.message_size == 0_u16
          details.message_size = IO::ByteFormat::BigEndian.decode(UInt16, details.send_size_buffer)
          details.message_buffer = details.data_buffer[0, details.message_size]
        end

        if details.message_bytes_read < details.message_size
          # Try to read the rest of the bytes.
          remaining_bytes = details.message_size - details.message_bytes_read
          read_buffer = details.message_buffer[details.message_bytes_read, remaining_bytes]
          bytes_read = @socket.not_nil!.read(read_buffer)
          details.message_bytes_read += bytes_read
        end

        if details.message_bytes_read >= details.message_size
          msg = Tuple(String, String, Array(String)).from_msgpack(details.message_buffer).as(Tuple(String, String, Array(String)))
          details.read_message_body = false
          details.read_message_size = true
          details.message_size = 0_u16
          details.message_bytes_read = 0_u16

          return msg
        else
          Fiber.yield
        end
      end
      nil
    end

    def setup_local_logging
      return if @logfile && !@logfile.not_nil!.closed?

      @logfile = File.open(tmplog, "a+")
      @io_details[@logfile.not_nil!] = IoDetails.new
      @destination = :local
    end

    def setup_remote
      @destination = :remote
    end

    def setup_reconnect_fiber
      return if @reconnection_fiber

      @reconnection_fiber = spawn do
        loop do
          sleep reconnect_throttle_interval
          begin
            connect
          rescue Exception
            nil
          end
          break if @socket && !closed?
        end
        @reconnection_fiber = nil
      end
    end

    # TODO: This is gross. Use overloading instead of doing this like it's Ruby.
    # def _send_remote(service, severity, message, flush_after_send = true)
    def _send_remote(
      verb : String | Symbol = "",
      uuid : UUID | String = UUID.new,
      data : Array(String) = [@group, @server] of String,
    )

      msg = Frame.new(verb, uuid, data)
      packed_msg = msg.to_msgpack
      _send_remote_impl(packed_msg, verb == :command)
    end

    def _send_remote(already_packed_msg : Slice(UInt8))
      _send_remote_impl(already_packed_msg)
    end

    def _send_remote_impl(packed_msg, flush = false)
      ssb = @io_details[@socket].send_size_buffer
      IO::ByteFormat::BigEndian.encode(packed_msg.size.to_u16, ssb)
      sock = @socket
      if sock.nil? || sock.closed?
        @authenticated = false
        setup_local_logging
        setup_reconnect_fiber
        @local_queue.send(packed_msg)
      else
        sock.write(ssb)
        sock.write(packed_msg)
        sock.flush if flush
      end
    rescue
      @authenticated = false
      setup_local_logging
      setup_reconnect_fiber
      @local_queue.send(packed_msg)
    end

    def _local_log(
      verb : String | Symbol = "",
      uuid : UUID | String = UUID.new,
      data : Array(String) = [@group, @server] of String
    )
      msg = Frame.new(verb, uuid, data)
      packed_msg = msg.to_msgpack
      _local_log_impl(packed_msg)
    end

    def _local_log(already_packed_msg : Slice(UInt8))
      _local_log_impl(already_packed_msg)
    end

    def _local_log_impl(packed_msg)
      @logfile.not_nil!.flock_exclusive
      @logfile.not_nil!.write packed_msg
    ensure
      @logfile.not_nil!.flock_unlock
    end

    def open_connection(host, port)
      TCPSocket.new(host, port)
    end

    def close_connection
      s = @socket
      if !s.nil?
        s.close if !s.closed?
        @io_details.delete(s)
      end
    end

    def register_failure
      @failed_at ||= Time.local
      @failure_count = @failure_count.not_nil! + 1
    end

    def fail_connect?
      failed_too_many? || failed_too_long?
    end

    def failed?
      !@failed_at.nil?
    end

    def failed_too_many?
      @failure_count.not_nil! > @max_failure_count
    end

    def failed_too_long?
      failed? && (@failed_at.not_nil! + Time::Span.new(seconds: @connection_failure_timeout)) < Time.local
    end

    def clear_failure
      @failed_at = nil
      @failure_count = 0
    end

    def authenticate
      begin
        @remote_queue.send({
          :command,
          UUID.new,
          [@group, @server, "authenticate-agent", @key],
          })
        until response = read
          Fiber.yield
        end
      rescue e : Exception
        STDERR.puts "\nauthenticate: #{e}\n#{e.backtrace.join("\n")}"
        response = nil
      end

      response = Frame.new(response.not_nil!)
      @authenticated = if response && response.data[0] =~ /accepted/
                         true
                       else
                         false
                       end
    end

    def there_is_a_swamp?
      tmplogs.each do |logfile|
        break true if File.exists?(logfile) && File.size(logfile) > 0
      end
    end

    def drain_the_swamp
      @swamp_drainer = spawn _drain_the_swamp unless @swamp_drainer && !@swamp_drainer.not_nil!.dead?
    end

    def non_blocking_lock_on_file_handle(file_handle)
      file_handle.flock_exclusive(false) ? yield : false
    ensure
      file_handle.flock_unlock
    end

    def _drain_the_swamp
      STDERR.puts "DRAINING"
      # As soon as we start emptying the local log file, ensure that no data
      # gets missed because of IO buffering. Otherwise, during high rates of
      # message sending, it is possible to get an EOF on file reading, and
      # assume all data has been sent, when there are actually records which
      # are buffered and just haven't been written yet.
      @logfile && (@logfile.not_nil!.sync = true)

      tmplogs.each do |logfile|
        File.exists?(logfile) && File.open(logfile) do |fh|
          non_blocking_lock_on_file_handle(fh) do # Only one process should read a given file.
            fh.fsync
            logfile_not_empty = true
            while logfile_not_empty
              record = read(fh) unless closed?
              if record
                STDERR.puts "  RECORD: #{Frame.new(record).inspect}"
                # record = Frame.new(record)
                Retriable.retry(max_interval: 1.minute, max_attempts: 0_u32 &- 1, multiplier: 1.05) do
                  # @remote_queue.send(record.to_msgpack)
                  @remote_queue.send(record)
                end
              else
                logfile_not_empty = false
              end
            end
            STDERR.puts "Deleting #{logfile}"
            File.delete logfile
          end
          setup_remote if tmplog == logfile
        end
      end

      @swamp_drainer = nil
    rescue e : Exception
      STDERR.puts "ERROR SENDING LOCALLY SAVED LOGS: #{e}\n#{e.backtrace.inspect}"
    end

    def authenticated?
      @authenticated
    end

    def reconnect
      connect(@host, @port)
    end

    def close
      @socket.not_nil!.close
    end

    def closed?
      @socket.not_nil!.closed?
    end

    # This only comes into play if a server ID is being fabricated by the client itself.
    # It tries to get the MAC address of the main interface on the system via a poor
    # heuristic, and if that fails, it just makes 6 random bytes.
    def build_identifier(random = false)
      match = nil
      unless random
        ip_lines = `ip link show`.split(/\n/).map(&.strip)
        q = [] of String
        while line = ip_lines.shift?
          if line =~ /<.*?UP.*?>/ && line =~ /<.*?BROADCAST/
            line += ip_lines.shift?.to_s
            q << line
          end
        end

        match = /(([a-f0-9]+):?){6}\s*$/.match q.sort.first
      end

      if match.nil? || random
        Random.new.random_bytes(6)
      else
        $0.split(/:/).join.hexbytes
      end
    end
  end
end
