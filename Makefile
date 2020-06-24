default: iar agent

iar: src/minion/iar.cr
	crystal build --release src/minion/iar.cr

agent: src/minion/agent.cr
	crystal build --release src/minion/agent.cr
