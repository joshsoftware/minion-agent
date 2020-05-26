package main

import (
	"crypto/tls"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"time"

	"github.com/fatih/color"
	"github.com/gorilla/websocket"
)

type session struct {
	ws      *websocket.Conn
	errChan chan error
}

// CommandOutput - an object holding the output from stderr or stdout, and the
// time at which that output occurred.
type CommandOutput struct {
	Output string    `json:"output"`
	At     time.Time `json:"at"`
}

// Command - represents a command to be issued by this agent
type Command struct {
	ID          string          `json:"id"`
	ServerID    string          `json:"server_id"`
	UserID      string          `json:"user_id"`
	Command     string          `json:"command"`
	STDERR      []CommandOutput `json:"stderr"`
	STDOUT      []CommandOutput `json:"stdout"`
	CreatedAt   int             `json:"created_at"`
	StartedAt   int             `json:"started_at"`
	CompletedAt int             `json:"completed_at"`
}

// NewCommands - used when the api has new commands for us to execute
type NewCommands struct {
	Action   string `json:"action"`
	ServerID string `json:"server_id"`
}

type Config struct {
	Location string `json:"location"`
	ServerID string `json:"server_id"`
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func main() {
	// Read config file, should be in same dir as this code
	cfile, err := ioutil.ReadFile("config.json")
	check(err)

	config := Config{}
	err = json.Unmarshal(cfile, &config)
	check(err)

	// Form a WebSocket connection
	headers := make(http.Header)
	headers.Add("Origin", config.Location)

	dialer := websocket.Dialer{
		Proxy: http.ProxyFromEnvironment,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}

	loc, err := url.Parse(config.Location)
	if err != nil {
		log.Fatalln(err)
	}

	ws, _, err := dialer.Dial(loc.String(), headers)
	if err != nil {
		log.Fatalln(err)
	}

	sess := &session{
		ws:      ws,
		errChan: make(chan error),
	}

	go sess.readWebsocket()
	<-sess.errChan
}

func bytesToFormattedHex(bytes []byte) string {
	text := hex.EncodeToString(bytes)
	return regexp.MustCompile("(..)").ReplaceAllString(text, "$1 ")
}

func (s *session) readWebsocket() {
	rxSprintf := color.New(color.FgGreen).SprintfFunc()

	for {
		msgType, buf, err := s.ws.ReadMessage()
		if err != nil {
			s.errChan <- err
			return
		}

		var text string
		switch msgType {
		case websocket.TextMessage:
			text = string(buf)
		case websocket.BinaryMessage:
			text = bytesToFormattedHex(buf)
		default:
			s.errChan <- fmt.Errorf("unknown websocket frame type: %d", msgType)
			return
		}

		fmt.Fprint(os.Stdout, rxSprintf("< %s\n", text))

		// This is where we figure out what the text says and act accordingly
		var f interface{}
		err = json.Unmarshal([]byte(text), &f)
		check(err)
		m := f.(map[string]interface{})
		fmt.Println(m["action"])

		switch m["action"] {
		case "connected":
			fmt.Println("Connection to Minion established!")
			// Now we need to subscribe to new commands
			go func() {
				sub := NewCommands{Action: "new_commands", ServerID: "abc123"} // TODO: Replace this with a real server id
				subjson, err := json.Marshal(sub)
				err = s.ws.WriteMessage(websocket.TextMessage, []byte(subjson))
				check(err)
				fmt.Printf("%+v\n", sub)
			}()
		case "output_command":
			fmt.Printf("%+v\n", m)
		case "new_commands":
			// The server is sending us a new command to execute
			newVal, _ := json.Marshal(m["new_val"])
			fmt.Println(string(newVal))
			newCmd := Command{}
			err = json.Unmarshal(newVal, &newCmd)
			check(err)
		case "update_command":
			fmt.Printf("%+v\n", m)
		default:
			fmt.Printf("Unknown action: %+v\n", m["action"])
			return
		}
	}
}
