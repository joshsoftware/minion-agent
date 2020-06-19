package logs

import (
	"io"
	"joshsoftware/minion-agent/appconfig"
	"log"

	"github.com/nxadm/tail"
)

// TailLogs - commences perpetual log tailing based on the logs configured in config.json
func TailLogs(config appconfig.Config) {
	seekloc := tail.SeekInfo{Offset: 0, Whence: io.SeekEnd}

	for _, l := range config.Logs {
		t, err := tail.TailFile(l, tail.Config{Follow: true, Location: &seekloc})
		if err != nil {
			// If the log file doesn't exist, don't crash, just report it
			// TODO: Put this in another package and call a more robust error handling system
			log.Println("WARN: ", err)
		}

		go func(logFile string) {
			for line := range t.Lines {
				// TODO: Wrap this up in a queue to be shipped to the server; if the server
				// is offline or can't be reached for some reason, add to the queue to be
				// resumed when everything comes back online.
				log.Println(logFile, line.Text)
			}
		}(l)
	}
}
