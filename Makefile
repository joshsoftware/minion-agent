compile:
	GOOS=linux GOARCH=amd64 go build -o build/linux/infinity infinity/infinity.go
	GOOS=linux GOARCH=amd64 go build -o build/linux/minion main.go
	GOOS=darwin GOARCH=amd64 go build -o build/macos/infinity infinity/infinity.go
	GOOS=darwin GOARCH=amd64 go build -o build/macos/minion main.go
