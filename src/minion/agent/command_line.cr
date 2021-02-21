module Minion
  class Agent
    class CommandLine
      def self.parse
        action = nil
        OptionParser.new do |opts|
          opts.on("-t", "--test", "Test the agent to make sure it works and can connect/authenticate with MINION") do
            action = "test"
          end

          opts.on("-r", "--run", "Run the agent in normal production mode (remember to specify CONFIG=/path/to/config.yml as an env var first)") do
            action = "run"
          end

          opts.on("-u", "--upgrade", "Upgrade the minion agent to the latest version") do
            action = "upgrade"
          end

          opts.on("-v", "--version", "Show agent version") do
            action = "version"
          end
        end.parse

        action
      end
    end
  end
end
