require "./telemetry"
require "./upgrade"
require "minion-common/src/minion/monkeys/file_info"

module Minion
  class Agent
    def self.run
      Minion::ConfigSource.rewind
      cfg = Minion::Config.from_yaml(Minion::ConfigSource.gets_to_end)

      Minion::Agent.startup(cfg)

      minion_client = Minion::Client.new(
        host: cfg.streamserver_host,
        port: cfg.streamserver_port,
        group: cfg.group_id,
        server: cfg.server_id,
        key: cfg.group_key,
        command_runner: ::Minion::Agent::CommandExecutor
      )

      ::Minion::Agent::CommandExecutor.client = minion_client

      spawn name: "builtin-telemetry" do
        start_at = Time.monotonic

        loop do
          cfg.builtin_telemetries.each do |builtin_telemetry|
            if builtin_telemetry.is_a?(Minion::Config::BuiltinTelemetry)
              label = builtin_telemetry.label
              args = builtin_telemetry.arguments
            else
              label = builtin_telemetry
              args = nil
            end

            case label.downcase
            when "memory"
              spawn_memory_telemetry(minion_client, args)
            when "load_avg"
              spawn_load_avg_telemetry(minion_client, args)
            when "disk_usage"
              spawn_disk_usage_telemetry(minion_client, args)
            end
          end

          sleep (cfg.telemetry_interval.to_f - ((Time.monotonic - start_at).to_f % cfg.telemetry_interval.to_f)) # Avoid clock creep from fixed sleep intervals.
        end
      end

      custom_telemetry_list = cfg.telemetries
      unless custom_telemetry_list.nil?
        custom_telemetry_list.each do |telemetry|
          do_telemetry(client: minion_client, telemetry: telemetry)
        end
      end

      # Tail logs and report new lines
      custom_tail_logs = cfg.tail_logs
      unless custom_tail_logs.nil?
        custom_tail_logs.each do |service|
          do_log(client: minion_client, service: service)
        end
      end

      loop do
        sleep 1
        # TODO: Implement this.
        # Listen for command dispatch
        # spawn name: "command" do
        #   # Execute command
        #   # Report stderr, stdout to ss
        # end
      end
    end

    def self.spawn_memory_telemetry(minion_client, args)
      # Report memory usage
      spawn name: "memory" do
        mem = Telemetry.mem_in_use
        minion_client.send("T", UUID.new, ["mem_used_kb", mem.to_s])
      end
    end

    def self.spawn_load_avg_telemetry(minion_client, args)
      # Report CPU usage
      spawn name: "load_avg" do
        loadavg = Telemetry.load_avg
        minion_client.send("T", UUID.new, ["load_avg", loadavg])
      end
    end

    def self.spawn_disk_usage_telemetry(minion_client, args)
      spawn name: "disk_usage" do
        minion_client.send("T", UUID.new, {"disk_usage" => Telemetry.disk_usage})
      end
    end

    def self.spawn_pickup_files_telemetry(minion_client, args)
      spawn name: "pick_files" do
        data = Telemetry.pick_files(args)
      end
    end

    def self.do_telemetry(client, telemetry : Minion::Config::CustomTelemetry)
      puts "Spawning custom telemetry for #{telemetry.name}..."
      spawn name: telemetry.name do
        loop do
          value = Telemetry.custom(telemetry).not_nil!
          client.send("T", UUID.new, [telemetry.name, value])
          sleep telemetry.interval
        end
      end
    end

    def self.do_log(client, service : Minion::Config::TailConfig)
      spawn do
        info : File::Info
        # If, on first entering this fiber, the log file already exists (and, most commonly, it will),
        # then seek to the end of the file before monitoring it.
        # Otherwise, if it does not exist, then when it appears, start reading from the beginning.
        if File.exists?(service.file)
          seek_to_end = true
        else
          seek_to_end = false
        end

        loop do
          begin
            # Wrap the whole thing in an exception handler, so on error it just...tries again.
            # The code needs to check the _creation_date_ of the file periodically. If it
            # changes from the original, that indicates that the file has been moved. If that
            # happens, finish reading, and then close and reopen.
            # It also needs to check file size. If file size _shrinks_, then the file has
            # been truncated. Seek back to the beginning and start reading.
            if File.exists?(service.file)
              info = File.info(service.file)
              previous_file_size = File.size(service.file)
              File.open(service.file) do |fh|
                fh.seek(offset: 0, whence: IO::Seek::End) if seek_to_end
                seek_to_end = true
                buffer = String::Builder.new
                loop do
                  new_size = fh.size
                  if new_size < previous_file_size
                    seek_to_end = false
                    break
                  else
                    previous_file_size = new_size
                  end

                  # It is possible in some cases for a partial write to get read before the full
                  # line is written. So the agent can never assume that it has received the full
                  # line until the \n is found at the end of it.
                  while chunk = fh.gets(delimiter: '\n')
                    if chunk
                      buffer << chunk.chomp
                      if chunk.not_nil![-1] == '\n'
                        client.send(verb: "L", data: [service.service, buffer.to_s])
                        buffer = String::Builder.new
                      end
                    end
                  end

                  # Detecting efficiently whether a file has moved or not seems to be a bit quirky.
                  # CTime changes when the file is moved, but CTime can also change if a file is simply
                  # appended to. So, the current algorithm is to check for a CTime change without any
                  # MTime change, and THEN to do a belt and suspenders test by checking that either a file
                  # at the original path does not exist, or that it exists, but it has a different inode.
                  if ((info.creation_time != fh.info.creation_time) &&
                     (info.modification_time == fh.info.modification_time)) ||
                     (!File.exists?(service.file) ||
                     (File.exists?(service.file) && (fh.info.inode != File.info(service.file).inode)))
                    seek_to_end = false
                    break
                  end

                  sleep 0.5
                end
              end
            else
              sleep 1
            end
          rescue ex : Exception
            msg = "Error during logging: #{ex}\n#{ex.backtrace.join("\n")}\n"
            puts msg
          end
        end
      end
    end
  end
end
