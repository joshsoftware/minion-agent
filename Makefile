default: agent

iar: src/minion/*.cr src/minion/client/*.cr
	crystal build --release src/minion/iar.cr

agent: src/minion/*.cr src/minion/agent/*.cr src/minion/client/*.cr
	crystal build --release src/minion/agent.cr
	rm json-server/public/agent
	cp ./agent json-server/public/agent

check: src/minion/*.cr src/minion/agent/*.cr src/minion/client/*.cr
	crystal build --no-codegen src/minion/agent.cr
	crystal build --no-codegen src/minion/iar.cr
