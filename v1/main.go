package main

import (
	"io"
	"joshsoftware/minion-agent/config"
	"log"
	"os"

	"github.com/nxadm/tail"
)

func main() {
	seekloc := tail.SeekInfo{Offset: 0, Whence: io.SeekEnd}
	config := config.ReadConfig(os.Getenv("CONFIG"))

	for _, l := range config.Logs {
		t, err := tail.TailFile(l, tail.Config{Follow: true, Location: &seekloc})
		if err != nil {
			// If the log file doesn't exist, don't crash, just report it
			// TODO: Put this in another package and call a more robust error handling system
			log.Println("WARN: ", err)
		}

		go func() {
			for line := range t.Lines {
				log.Println(line.Text)
			}
		}()
	}

	for {
	}
}
