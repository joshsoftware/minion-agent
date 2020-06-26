require "./telemetry"

module Minion
  class Agent
    def self.run
      cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"]))
      Minion::Agent.startup(cfg)

      ss = Minion::Client.new(
        host: cfg.streamserver_host,
        port: cfg.streamserver_port,
        group: cfg.group_id,
        server: cfg.server_id,
        key: cfg.group_key
      )

      spawn name: "telemetry" do
        loop do
          # Report memory usage
          mem = Telemetry.mem_in_use
          ss.send("T", UUID.new, ["mem_used_kb", mem.to_s])

          # Report CPU usage
          loadavg = Telemetry.load_avg
          ss.send("T", UUID.new, ["load_avg", loadavg])

          # TODO: Disk usage, swap
          sleep 5
        end
      end

      # Tail logs and report new lines
      cfg.tail_logs.each do |service|
        if File.exists?(service.file)
          spawn do
            File.open(service.file) do |fh|
              puts "Opened file: #{service.file}"
              fh.seek(offset: 0, whence: IO::Seek::End)
              loop do
                puts "Reading from #{service.file}..."
                while line = fh.gets
                  puts "Sending the following: #{line}"
                  ss.send(verb: "L", data: [service.service, service.file, line])
                end
                sleep 0.5
              end
            end
          end
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
  end
end
