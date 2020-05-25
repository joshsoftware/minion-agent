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

	"github.com/fatih/color"
	"github.com/gorilla/websocket"
)

type session struct {
	ws      *websocket.Conn
	errChan chan error
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

	fmt.Printf("%+v\n", config)

	headers := make(http.Header)
	headers.Add("Origin", config.Location)

	fmt.Printf("%+v\n", headers)

	dialer := websocket.Dialer{
		Proxy: http.ProxyFromEnvironment,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	fmt.Printf("%+v\n", dialer)

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
	}
}
