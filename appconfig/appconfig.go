package appconfig

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"time"
)

// Config - represents the structure for the application's configuration
type Config struct {
	Logs             []string  `json:"logs"`
	ServerID         string    `json:"server_id"`
	ServerKey        string    `json:"server_key"`
	OrgID            string    `json:"org_id"`
	OrgKey           string    `json:"org_key"`
	RegistrationDate time.Time `json:"registration_date"`
	StreamserverIP   string    `json:"streamserver_ip"`
	StreamserverPort int32     `json:"streamserver_port"`
}

// ReadConfig - call at application startup to create a config object to read from
func ReadConfig(filename string) (config Config) {
	configFile, err := ioutil.ReadFile(filename)
	if err != nil {
		// DO crash on app startup if can't read config
		log.Fatalln("Cannot read configuration file at ", os.Getenv("CONFIG"), err)
		return
	}
	config = Config{}
	err = json.Unmarshal(configFile, &config)
	if err != nil {
		// DO crash on app startup if can't get config
		log.Fatalln("Cannot unmarshal json in config.ReadConfig() using file file "+filename, err)
		return
	}
	return
}

// WriteConfig - write out a configuration file at the ENV['CONFIG'] location
func WriteConfig(filename string, config Config) (err error) {
	json, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		log.Println("Cannot marshal JSON in WriteConfig", err)
		return
	}
	err = ioutil.WriteFile(os.Getenv("CONFIG"), json, 0644)
	if err != nil {
		log.Println("Cannot write config file; changes will be lost when the program exits", err)
	}
	return
}
