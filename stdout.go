package main

import (
	"bufio"
	"fmt"
	"os/exec"
)

/*
func main() {
	// cmd := exec.Command("bash", "-c", `"while true; do date; sleep 1; done"`)
	cmd := exec.Command("/Users/jah/Projects/minion/agent/infinity")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}
	//	var person struct {
	//		Name string
	//		Age  int
	//	}
	//	if err := json.NewDecoder(stdout).Decode(&person); err != nil {
	//		log.Fatal(err)
	//	}
	// if err := cmd.Wait(); err != nil {
	// 	log.Fatal(err)
	// }
	//	fmt.Printf("%s is %d years old\n", person.Name, person.Age)
	// fmt.Println(stdout)

	for {
		out, _ := stdout.Read()
		fmt.Printf("%+v\n", out)
	}
}
*/

func main() {
	// args := "-i test.mp4 -acodec copy -vcodec copy -f flv rtmp://aaa/bbb"
	cmd := exec.Command("/Users/jah/Projects/minion/agent/infinity")

	stdout, _ := cmd.StdoutPipe()
	cmd.Start()

	scanner := bufio.NewScanner(stdout)
	scanner.Split(bufio.ScanWords)
	for scanner.Scan() {
		m := scanner.Text()
		fmt.Println(m)
	}
	cmd.Wait()
}
