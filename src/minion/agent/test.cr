module Minion
  class Agent
    def self.test
      cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"]))
      Minion::Agent.startup(cfg)
      ss = Minion::Client.new(
        host: cfg.streamserver_host,
        port: cfg.streamserver_port,
        group: cfg.group_id,
        server: cfg.server_id,
        key: cfg.group_key
      )
    end
  end
end
