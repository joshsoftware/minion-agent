package main

import (
	"bufio"
	"joshsoftware/minion-agent/appconfig"
	"joshsoftware/minion-agent/lifecycle"
	"joshsoftware/minion-agent/logs"
	"log"
	"os"
	"os/exec"
)

func main() {
	cfg := appconfig.ReadConfig(os.Getenv("CONFIG"))
	if !lifecycle.IsRegistered(cfg) {
		lifecycle.Register(cfg)
	}
	go logs.TailLogs(cfg)

	// Test writing the config
	err := appconfig.WriteConfig(os.Getenv("CONFIG"), cfg)
	if err != nil {
		log.Println(err)
	}

	go func() {
		cmd := exec.Command("bash", "-c", "echo stdout; sleep 5; echo 1>&2 stderr; sleep 5; echo 1>&2 morestderr; sleep 5")
		stderr, err := cmd.StderrPipe()

		if err != nil {
			log.Fatal(err)
		}

		stdout, err := cmd.StdoutPipe()

		if err != nil {
			log.Fatal(err)
		}

		scannererr := bufio.NewScanner(stderr)
		scannerout := bufio.NewScanner(stdout)

		if err := cmd.Start(); err != nil {
			log.Fatal(err)
		}

		go func() {
			for scannerout.Scan() {
				log.Println(scannerout.Text())
			}
		}()

		go func() {
			for scannererr.Scan() {
				log.Println(scannererr.Text())
			}
		}()

		if err := cmd.Wait(); err != nil {
			log.Fatal(err)
		}
	}()

	// Primary command listening & execution loop
	for {
		// TODO: Check for unsent logs and send them if they exist
		// TODO: Check for new commands
		// TODO: Execute those commands in a goroutine
		// TODO: Report command STDERR/STDOUT to StreamServer
	}
}

//  C::test-group-2::authenticate-agent::798c733ba086c606fa8a925ab69bebf1cc44ee11a19ac81eaa4689774a6b6b04
