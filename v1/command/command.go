package command

import (
	"os/exec"
)

// TODO: Define a timeout to kill a command in case it gets stuck waiting on
// stdin or something.

// Build - todo: explain it
func Build(path string, args []string, env []string, dir string) (cmd exec.Cmd) {

}
