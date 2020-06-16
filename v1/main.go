package main

import (
	"joshsoftware/minion-agent/config"
	"joshsoftware/minion-agent/lifecycle"
	"joshsoftware/minion-agent/logs"
	"log"
	"os"
)

func main() {
	cfg := config.ReadConfig(os.Getenv("CONFIG"))
	if !lifecycle.IsRegistered(cfg) {
		lifecycle.Register(cfg)
	}
	go logs.TailLogs(cfg)

	// Test writing the config
	err := config.WriteConfig(os.Getenv("CONFIG"), cfg)
	if err != nil {
		log.Println(err)
	}

	// Primary command listening & execution loop
	for {
		// TODO: Check for new commands
		// TODO: Check for unsent logs and send them if they exist
		// TODO: Execute those commands in a goroutine
		// TODO: Report command STDERR/STDOUT to StreamServer
	}
}
