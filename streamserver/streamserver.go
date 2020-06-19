package streamserver

import (
	"joshsoftware/minion-agent/appconfig"
	"log"
)

// Connect - Pass in an appconfig.Config object and it returns an open,
// active connection along with an error if an error occurred.
//
// Example usage:
//		ss, err := streamserver.Connect(cfg)
//		if err!= nil {
//			panic("Cannot connect to streamserver!")
//		}
func Connect(cfg appconfig.Config) (c int32, err error) {
	c = 42
	log.Println("Connecting to ", cfg.StreamserverIP, ":", cfg.StreamserverPort)
	return
}
