package main

import (
	"joshsoftware/minion-agent/config"
	"joshsoftware/minion-agent/logs"
	"os"
)

func main() {
	config := config.ReadConfig(os.Getenv("CONFIG"))
	logs.TailLogs(config)
	for {
	}
}
