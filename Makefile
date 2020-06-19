run:
	GOOS=darwin GOARCH=amd64 go build -o ./minion-agent
	CONFIG=$(CURDIR)/config.json ./minion-agent

compile:
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o build/macos/minion-agent
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o build/linux/minion-agent
	upx --brute build/macos/minion-agent
	# upx --brute build/linux/minion-agent

debug:
	CONFIG=$(CURDIR)/config.json dlv debug main.go
