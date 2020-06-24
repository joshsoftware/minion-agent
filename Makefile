default: iar agent

iar: src/minion/*.cr
	crystal build --release src/minion/iar.cr

agent: src/minion/*.cr
	crystal build --release src/minion/agent.cr
