require "option_parser"
require "./client"
require "./agent/config"
require "./agent/startup"
require "./agent/test"
require "./agent/version"
require "./agent/exec"

OptionParser.new do |opts|
  opts.on("-t", "--test", "Test the agent to make sure it works and can connect/authenticate with MINION") do
    Minion::Agent.test
  end

  opts.on("-r", "--run", "Run the agent in normal production mode (remember to specify CONFIG=/path/to/config.yml as an env var first)") do
    Minion::Agent.run
  end

  opts.on("-v", "--version", "Show agent version") do
    puts Minion::Agent::VERSION
  end
end.parse
