default:
	crystal build --release src/minion/client.cr
	crystal build --release src/minion/iar.cr

iar:
	crystal build --release src/minion/iar.cr