module Minion
  class Agent
    def self.startup(cfg)
      # Diagnostic information for the operator
      puts "Starting Minion Agent v#{VERSION} with the following configuration (from #{ENV["CONFIG"]})"
      puts "Streamserver: \t\t #{cfg.streamserver_host}:#{cfg.streamserver_port}"
      puts "Group ID: \t\t #{cfg.group_id}"
      puts "Group Key: \t\t #{cfg.group_key}"
      puts "Server ID: \t\t #{cfg.server_id}"
      puts "Server Name: \t\t #{cfg.server_name}"
    end
  end
end
