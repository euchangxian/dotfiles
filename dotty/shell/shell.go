// Package shell is responsible for providing a interface to os/exec
package shell

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
)

type CmdResult struct {
	Output   string
	ExitCode int
}

type Executor struct {
	DryRun  bool
	BaseEnv []string

	// Writer allows us to redirect output (e.g. to a log file)
	// to prevent interfering with the TUI.
	Writer io.Writer
}

func New(dryRun bool, writer io.Writer) *Executor {
	fullEnv := os.Environ()
	baseEnv := make([]string, 0, len(fullEnv))
	for _, e := range fullEnv {
		if !strings.HasPrefix(e, "PATH=") {
			baseEnv = append(baseEnv, e)
		}
	}

	if writer == nil {
		writer = os.Stdout
	}

	return &Executor{
		DryRun:  dryRun,
		BaseEnv: baseEnv,
		Writer:  writer,
	}
}

// Run executes a command interactively (stdin/stdout connected to terminal)
// envPath is the "Sandboxed PATH" we are maintaining.
func (e *Executor) Run(name string, args []string, envPath string) error {
	if e.DryRun {
		return e.logCmd(name, args)
	}

	cmd := exec.Command(name, args...)
	cmd.Stdin = os.Stdin

	cmd.Stdout = e.Writer
	cmd.Stderr = e.Writer
	e.injectEnv(cmd, envPath)

	return cmd.Run()
}

// Output runs silently and captures stdout (for Check operations)
func (e *Executor) Output(name string, args []string, envPath string) (string, error) {
	if e.DryRun {
		return "", e.logCmd(name, args)
	}

	cmd := exec.Command(name, args...)
	e.injectEnv(cmd, envPath)

	out, err := cmd.Output()
	return strings.TrimSpace(string(out)), err
}

// injectEnv constructs the environment for the command.
// It inherits the current process environment but overwrites PATH.
func (e *Executor) injectEnv(cmd *exec.Cmd, envPath string) {
	finalEnv := make([]string, len(e.BaseEnv), len(e.BaseEnv)+1)
	copy(finalEnv, e.BaseEnv)

	if envPath != "" {
		finalEnv = append(finalEnv, fmt.Sprintf("PATH=%s", envPath))
	}
	cmd.Env = finalEnv
}

func (e *Executor) logCmd(name string, args []string) error {
	cmdStr := fmt.Sprintf("%s %s", name, strings.Join(args, " "))
	_, err := fmt.Fprintf(e.Writer, "\x1b[36m[CMD]\x1b[0m %s\n", cmdStr)
	if err != nil {
		return err
	}
	return nil
}
