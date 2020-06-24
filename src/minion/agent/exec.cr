module Minion
  class Agent
    def self.exec
      cfg = Minion::Config.from_yaml(File.read(ENV["CONFIG"]))

      # Diagnostic information for the operator
      puts "Starting Minion Agent with the following configuration (from #{ENV["CONFIG"]})"
      puts "Streamserver: \t\t #{cfg.streamserver_host}:#{cfg.streamserver_port}"
      puts "Group ID: \t\t #{cfg.group_id}"
      puts "Group Key: \t\t #{cfg.group_key}"
      puts "Server ID: \t\t #{cfg.server_id}"
      puts "Server Name: \t\t #{cfg.server_name}"

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
