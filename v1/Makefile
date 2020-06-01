run:
	GOOS=darwin GOARCH=amd64 go build -o build/macos/minion-agent
	CONFIG=$(CURDIR)/config.json ./build/macos/minion-agent

build:
	GOOS=darwin GOARCH=amd64 go build -o build/macos/minion-agent
	GOOS=linux GOARCH=amd64 go build -o build/linux/minion-agent
