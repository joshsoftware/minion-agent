package config

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
)

// Config - represents the structure for the application's configuration
type Config struct {
	Logs      []string `json:"logs"`
	ServerID  string   `json:"server_id"`
	ServerKey string   `json:"server_key"`
}

// ReadConfig - call at application startup to create a config object to read from
func ReadConfig(filename string) (config Config) {
	configFile, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatalln("Cannot read configuration file at ", os.Getenv("CONFIG"), err)
		return
	}
	config = Config{}
	err = json.Unmarshal(configFile, &config)
	if err != nil {
		log.Fatalln("Cannot unmarshal json in config.ReadConfig() using file file "+filename, err)
		return
	}
	return
}
