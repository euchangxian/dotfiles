// Package managers handle the abstraction of shell commands.
package managers

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"dotty/engine"
	"dotty/manifest"
)

// base provides a common implementation for shell-based managers to reduce boilerplate.
type base struct {
	installArgs func(manifest.Instruction) (string, []string)
}

// RequiresPrivilege defaults to false.
// Specific managers (like DNF) can override this.
func (b *base) RequiresPrivilege(instr manifest.Instruction) bool {
	return false
}

// GetCommand provides a consistent way to display the command that will be run.
func (b *base) GetCommand(env engine.Env, instruction manifest.Instruction) string {
	name, args := b.installArgs(instruction)
	return fmt.Sprintf("%s %s", name, strings.Join(args, " "))
}

// Install provides a shared execution loop using the engine's shell.
func (b *base) Install(ctx context.Context, env engine.Env, instr manifest.Instruction, onLine func(string)) error {
	name, args := b.installArgs(instr)
	return env.Shell.Run(ctx, name, args, env.PATH, onLine)
}

type Shell struct{ base }

func NewShell() *Shell {
	m := &Shell{}
	m.installArgs = func(instr manifest.Instruction) (string, []string) {
		return "sh", []string{"-c", instr.InstallCmd}
	}
	return m
}

func (m *Shell) Exists(ctx context.Context, env engine.Env, instruction manifest.Instruction) bool {
	if instruction.CheckCmd == "" {
		return false
	}
	_, err := env.Shell.Output(ctx, "sh", []string{"-c", instruction.CheckCmd}, env.PATH)
	return err == nil
}

func (m *Shell) Install(ctx context.Context, env engine.Env, instr manifest.Instruction, onLine func(string)) error {
	if instr.InstallCmd == "" {
		return errors.New("shell manager requires an 'install' command")
	}
	return m.base.Install(ctx, env, instr, onLine)
}

type Dnf struct{ base }

func NewDnf() *Dnf {
	m := &Dnf{}
	m.installArgs = func(instr manifest.Instruction) (string, []string) {
		return "sudo", []string{"dnf", "install", "-y", instr.Package}
	}
	return m
}

func (m *Dnf) RequiresPrivilege(instr manifest.Instruction) bool {
	return true // DNF installs requires sudo
}

func (m *Dnf) Exists(ctx context.Context, env engine.Env, instruction manifest.Instruction) bool {
	_, err := env.Shell.Output(ctx, "rpm", []string{"-q", instruction.Package}, env.PATH)
	return err == nil
}

type Homebrew struct{ base }

func NewHomebrew() *Homebrew {
	m := &Homebrew{}
	m.installArgs = func(instr manifest.Instruction) (string, []string) {
		return "brew", []string{"install", instr.Package}
	}
	return m
}

func (m *Homebrew) Exists(ctx context.Context, env engine.Env, instruction manifest.Instruction) bool {
	_, err := env.Shell.Output(ctx, "brew", []string{"list", instruction.Package}, env.PATH)
	return err == nil
}

type Cargo struct{ base }

func NewCargo() *Cargo {
	m := &Cargo{}
	m.installArgs = func(instr manifest.Instruction) (string, []string) {
		return "cargo", []string{"install", "--locked", instr.Package}
	}
	return m
}

func (m *Cargo) Exists(ctx context.Context, env engine.Env, instruction manifest.Instruction) bool {
	out, err := env.Shell.Output(ctx, "cargo", []string{"install", "--list"}, env.PATH)
	if err != nil {
		return false
	}
	return strings.Contains(out, instruction.Package+" v")
}
