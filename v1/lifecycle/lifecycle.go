package lifecycle

import (
	"joshsoftware/minion-agent/config"
	"log"
	"os"
	"time"
)

// IsRegistered - tell us whether or not this agent is registered
// TODO: Once the API is implemented, have it ask the API whether or not it's
// been registered.
func IsRegistered(config config.Config) (registered bool) {
	registered = false
	return
}

// Register - talks to the API and asks for the server's unique ID and key,
// then sets this information in the config file (os.Getenv("CONIFG")).
// TODO: Integrate with API
func Register(cfg config.Config) (err error) {
	cfg.RegistrationDate = time.Now().UTC()
	cfg.ServerID = "abc123"              // Get this from the API
	cfg.ServerKey = "welcometothejungle" // Get this from the API

	// Write out the configuration file and reload it
	err = config.WriteConfig(os.Getenv("CONFIG"), cfg)
	if err != nil {
		log.Println("WARN: Could not write config after registration", err)
		return
	}
	return
}
