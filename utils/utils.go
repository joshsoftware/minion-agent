package utils

import (
	"bytes"
	"encoding/binary"
	"log"
	"time"
)

// NewUUID - returns a new UUID in a format suitable for the streamserver
func NewUUID() (uuid string) {
	// Get the current time
	now := time.Now()
	epoch := time.Date(0000, time.January, 01, 0, 0, 0, 0, time.UTC)
	dur := now.Sub(epoch)
	nanoseconds := uint32(now.Nanosecond())
	seconds := dur.Seconds()
	log.Printf("%f", seconds)
	log.Printf("%d", int32(nanoseconds))

	// Declare a buffer we can use for converting to BigEndian
	b := make([]byte, 4)
	buf := bytes.NewReader(b)
	var chunk1 uint32
	binary.BigEndian.PutUint32(b, nanoseconds)
	err := binary.Read(buf, binary.BigEndian, &chunk1)
	if err != nil {
		log.Println(err)
	}

	// Convert chunk1 into hex for the first "chunk" of the UUID

	return
}

/* On the formation of UUIDs for the client to send to the server:

A UUID is 16 bytes, formatted chunks of 6-2-2-6 bytes, in hexadecimal notation.

So:
04146794000e-d683-22c9-d8c7329fab41	214afa6c000e-d683-22bc-f8e4e3897173	stderr	here is an example with uuids
15917df4000e-d683-22d8-60633e536cd6	214afa6c000e-d683-22bc-f8e4e3897173	stderr	here is another example with uuids

Nanoseconds, as a signed 32 bit integer.  Nanoseconds readily fits into a 32 bit
integer even though Go uses a 64bit for them.

For seconds, though, it does not fit into a 32 bit integer.  At the same time,
8 full bytes -- 64 bits -- is enough seconds to last until the heat death of the
universe. So, because space is at a premium in a UUID, I just chopped 2 of the
bytes off since they will always be 0 anyway.

4:20
So, you get the current time, and get the nanoseconds for the current seconds,
as well as the seconds since 0001-01-01 00:00:00.0 UTC.  Make the nanoseconds a
32 bit integer. Convert that to Big Endian (Most significant byte first)
hexadecimal.

Do the same with your seconds, but only keep 6 of the 8 bytes since you are just
chopping off 0s anyway (and, really, we could chop off 3 of those bytes as I
doubt that Minion will still be in use by the time that 6th byte is needed),
and then tack on 6 random bytes at the end.

*/
