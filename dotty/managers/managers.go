// Package managers handle the abstraction of shell commands.
package managers

import (
	"errors"
	"fmt"
	"strings"

	"dotty/engine"
	"dotty/manifest"
)

type Shell struct{}

func (m *Shell) Exists(ctx engine.Context, instruction manifest.Instruction) bool {
	if instruction.CheckCmd == "" {
		// If there is no check command, assume it's not installed/needs running.
		return false
	}

	// use "sh -c" to allow piping and complex commands in the YAML check string
	// e.g. "dnf repolist | grep rpmfusion"
	_, err := ctx.Shell.Output("sh", []string{"-c", instruction.CheckCmd}, ctx.PATH)
	return err == nil
}

func (m *Shell) getInstallArgs(instruction manifest.Instruction) (string, []string) {
	return "sh", []string{"-c", instruction.InstallCmd}
}

func (m *Shell) GetCommand(ctx engine.Context, instruction manifest.Instruction) string {
	// For Shell, we return the raw command for display if possible, or the full sh -c wrapper
	// To be strictly consistent with the refactor pattern:
	name, args := m.getInstallArgs(instruction)
	return fmt.Sprintf("%s %s", name, strings.Join(args, " "))
}

func (m *Shell) Install(ctx engine.Context, instruction manifest.Instruction, onLine func(string)) error {
	if instruction.InstallCmd == "" {
		return errors.New("shell manager requires an 'install' command")
	}
	name, args := m.getInstallArgs(instruction)
	return ctx.Shell.Run(name, args, ctx.PATH, onLine)
}

type Dnf struct{}

func (m *Dnf) Exists(ctx engine.Context, instruction manifest.Instruction) bool {
	_, err := ctx.Shell.Output("rpm", []string{"-q", instruction.Package}, ctx.PATH)
	return err == nil
}

func (m *Dnf) getInstallArgs(instruction manifest.Instruction) (string, []string) {
	return "sudo", []string{"dnf", "install", "-y", instruction.Package}
}

func (m *Dnf) GetCommand(ctx engine.Context, instruction manifest.Instruction) string {
	name, args := m.getInstallArgs(instruction)
	return fmt.Sprintf("%s %s", name, strings.Join(args, " "))
}

func (m *Dnf) Install(ctx engine.Context, instruction manifest.Instruction, onLine func(string)) error {
	name, args := m.getInstallArgs(instruction)
	return ctx.Shell.Run(name, args, ctx.PATH, onLine)
}

type Homebrew struct{}

func (m *Homebrew) Exists(ctx engine.Context, instruction manifest.Instruction) bool {
	// "brew list <package>" returns 0 if installed (works for formulae and casks)
	_, err := ctx.Shell.Output("brew", []string{"list", instruction.Package}, ctx.PATH)
	return err == nil
}

func (m *Homebrew) getInstallArgs(instruction manifest.Instruction) (string, []string) {
	return "brew", []string{"install", instruction.Package}
}

func (m *Homebrew) GetCommand(ctx engine.Context, instruction manifest.Instruction) string {
	name, args := m.getInstallArgs(instruction)
	return fmt.Sprintf("%s %s", name, strings.Join(args, " "))
}

func (m *Homebrew) Install(ctx engine.Context, instruction manifest.Instruction, onLine func(string)) error {
	name, args := m.getInstallArgs(instruction)
	return ctx.Shell.Run(name, args, ctx.PATH, onLine)
}

type Cargo struct{}

func (m *Cargo) Exists(ctx engine.Context, instruction manifest.Instruction) bool {
	// cargo install --list returns installed packages. grep for the specific one.
	out, err := ctx.Shell.Output("cargo", []string{"install", "--list"}, ctx.PATH)
	if err != nil {
		return false
	}
	return strings.Contains(out, instruction.Package+" v")
}

func (m *Cargo) getInstallArgs(instruction manifest.Instruction) (string, []string) {
	return "cargo", []string{"install", "--locked", instruction.Package}
}

func (m *Cargo) GetCommand(ctx engine.Context, instruction manifest.Instruction) string {
	name, args := m.getInstallArgs(instruction)
	return fmt.Sprintf("%s %s", name, strings.Join(args, " "))
}

func (m *Cargo) Install(ctx engine.Context, instruction manifest.Instruction, onLine func(string)) error {
	name, args := m.getInstallArgs(instruction)
	return ctx.Shell.Run(name, args, ctx.PATH, onLine)
}
