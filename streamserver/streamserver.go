package streamserver

import (
	"bytes"
	"fmt"
	"joshsoftware/minion-agent/appconfig"
	"log"
	"net"

	"github.com/vmihailenco/msgpack"
)

// Message - used to represent a message to be encoded/decoded by msgpack
type Message struct {
	_msgpack struct{} `msgpack:",asArray"`
	ID       string
	UUID     string
	Data     []string
}

// AuthMessage - used to authenticate (different message structure than standard
// streamserver messages)
type AuthMessage struct {
	_msgpack struct{} `msgpack:",asArray"`
	GroupID  string
	ServerID string
	Command  string
	Key      string
}

/*

So a message to the streamserver consists of a msgpack-encoded array:
[verb, dest, [data1, data2, ...dataN]]

Where [data] is an array of strings, verb is "log" or something like it,
"dest" is like "stderr" (for now).

You msgpack that thing into an array then calculate its length. Then you send
TWO messages directly to the streamserver, one after the other:

1. The message length
2. The message

The length has to be a Big Endian, unsigned 16-bit integer.

*/

// Connect - Pass in an appconfig.Config object and it returns an open,
// active connection along with an error if an error occurred.
//
// Example usage:
//		ss, err := streamserver.Connect(cfg)
//		if err!= nil {
//			panic("Cannot connect to streamserver!")
//		}
func Connect(cfg appconfig.Config) (c net.Conn, err error) {
	endpoint := fmt.Sprintf("%s:%d", cfg.StreamserverIP, cfg.StreamserverPort)
	log.Println("Connecting to ", endpoint)
	c, err = net.Dial("tcp", endpoint)
	return
}

// Authenticate - given the network connection and configuration, authenticate
// with the streamserver by sending an authentication command.
func Authenticate(c *net.Conn, cfg appconfig.Config) (err error) {
	auth := AuthMessage{
		GroupID:  cfg.OrgID,
		Key:      cfg.OrgKey,
		ServerID: cfg.ServerID,
		Command:  "authenticate-agent",
	}
	log.Println(auth)

	var buf bytes.Buffer
	enc := msgpack.NewEncoder(&buf)
	err = enc.Encode(auth)

	// Try to send the authenticate message over to the streamserver
	// n, err := c.Write()

	dec := msgpack.NewDecoder(&buf)
	v, err := dec.DecodeInterface()
	log.Println(v)

	// in := map[string]interface{}{"foo": "bar"}
	// log.Println(in)
	// b, _ := msgpack.Marshal(in)
	// var out map[string]interface{}
	// _ = msgpack.Unmarshal(b, &out)
	// log.Println("foo = ", out["foo"])
	return
}
