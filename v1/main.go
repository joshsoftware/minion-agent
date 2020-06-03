package main

import (
	"joshsoftware/minion-agent/config"
	"joshsoftware/minion-agent/lifecycle"
	"joshsoftware/minion-agent/logs"
	"os"
)

func main() {
	config := config.ReadConfig(os.Getenv("CONFIG"))
	if !lifecycle.IsRegistered(config) {
		lifecycle.Register(config)
	}
	go logs.TailLogs(config)
	for {
	}
}
