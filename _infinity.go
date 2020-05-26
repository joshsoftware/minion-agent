package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	for i := 0; i < 10; i++ {
		fmt.Println(fmt.Sprintf("%v", time.Now().Unix()))
		time.Sleep(333 * time.Millisecond)
		fmt.Fprintln(os.Stderr, "Iteration number ", i)
		time.Sleep(666 * time.Millisecond)
	}

}
