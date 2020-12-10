module Minion
  class Agent
    def self.test
      begin
        cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"]))
      rescue exception
        puts exception
        STDERR.puts "Could not parse config file #{ENV["CONFIG"]}"
        exit 1
      end

      Minion::Agent.startup(cfg)

      begin
        Minion::Client.new(
          host: cfg.streamserver_host,
          port: cfg.streamserver_port,
          group: cfg.group_id,
          server: cfg.server_id,
          key: cfg.group_key,
          fail_immediately: true
        )
      rescue exception
        STDERR.puts "Could not connect to MINION service; exiting"
        exit 1
      end
    end
  end
end
