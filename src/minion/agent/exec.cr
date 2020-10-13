require "./telemetry"
require "./upgrade"
require "minion-common/src/minion/monkeys/file_info"

module Minion
  class Agent
    def self.run
      Minion::ConfigSource.rewind
      cfg = Minion::Config.from_yaml(Minion::ConfigSource.gets_to_end)

      Minion::Agent.startup(cfg)

      ss = Minion::Client.new(
        host: cfg.streamserver_host,
        port: cfg.streamserver_port,
        group: cfg.group_id,
        server: cfg.server_id,
        key: cfg.group_key,
        command_runner: ::Minion::Agent::CommandExecutor
      )

      ::Minion::Agent::CommandExecutor.client = ss

      spawn name: "telemetry" do
        start_at = Time.monotonic

        loop do
          # Report memory usage
          spawn name: "memory" do
            mem = Telemetry.mem_in_use
            ss.send("T", UUID.new, ["mem_used_kb", mem.to_s])
          end

          # Report CPU usage
          spawn name: "load_avg" do
            loadavg = Telemetry.load_avg
            ss.send("T", UUID.new, ["load_avg", loadavg])
          end

          spawn name: "disk_usage" do
            ss.send("T", UUID.new, {"disk_usage" => Telemetry.disk_usage})
          end

          # swap
          sleep (60 - ((Time.monotonic - start_at).to_f % 60.0)) # Avoid clock creep from fixed sleep intervals.
        end
      end

      unless cfg.telemetries.nil?
        cfg.telemetries.not_nil!.each do |telemetry|
          do_telemetry(client: ss, telemetry: telemetry)
        end
      end

      # Tail logs and report new lines
      unless cfg.tail_logs.nil?
        cfg.tail_logs.not_nil!.each do |service|
          do_log(client: ss, service: service)
        end
      end

      loop do
        sleep 1
        # Listen for command dispatch
        # spawn name: "command" do
        #   # Execute command
        #   # Report stderr, stdout to ss
        # end
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
                loop do
                  new_size = fh.size
                  if new_size < previous_file_size
                    seek_to_end = false
                    break
                  else
                    previous_file_size = new_size
                  end

                  while chunk = fh.gets(delimiter: '\n')
                    if chunk
                      client.send(verb: "L", data: [service.service, chunk.chomp])
                    end
                  end

                  # Detecting efficiently whether a file has moved or not seems to be a bit quirky.
                  # CTime changes when the file is moved, but CTime can also change if a file is simply
                  # appended to. So, the current algorithm is to check for a CTime change without any
                  # MTime change, and THEN to do a belt and suspenders test by checking that either a file
                  # at the original path does not exist, or that it exists, but it has a different inode.
                  if ((info.creation_time != fh.info.creation_time) &&
                     (info.modification_time == fh.info.modification_time)) ||
                     ( !File.exists?(service.file) ||
                       ( File.exists?(service.file) && (fh.info.inode != File.info(service.file).inode)))
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
