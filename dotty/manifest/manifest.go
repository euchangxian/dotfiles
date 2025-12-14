// Package manifest handle the definitions of the Package.yaml file.
package manifest

import (
	"os"

	"gopkg.in/yaml.v3"
)

type OSName = string

const (
	OSFedora OSName = "fedora"
	OSMac    OSName = "darwin"
)

type ManagerName = string

const (
	ManagerBrew  ManagerName = "brew"
	ManagerDNF   ManagerName = "dnf"
	ManagerCargo ManagerName = "cargo"
	ManagerGo    ManagerName = "go"
	ManagerShell ManagerName = "shell"
)

type Manifest struct {
	Stages []Stage `yaml:"stages"`
}

type Stage struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	Steps       []Step `yaml:"steps"`
}

type Step struct {
	Name         string                 `yaml:"name"`
	EnvUpdate    bool                   `yaml:"env_update"`
	Instructions map[OSName]Instruction `yaml:"instructions"`
}

type Instruction struct {
	Manager ManagerName `yaml:"manager"`

	// CheckCmd is a raw shell command to verify existence (exit code 0 = exists)
	CheckCmd string `yaml:"check,omitempty"`

	// Binary is the name of the executable to check in $PATH (e.g. "nvim", "cargo")
	// If present, this takes precedence over the Manager's check logic.
	Binary string `yaml:"binary,omitempty"`

	// Ordered by precedence: if a command is provided, then that likely means
	// the user intends for the command to be executed.
	// But most usage should be either (Shell, InstallCmd) or (Others, Package)
	InstallCmd string `yaml:"install,omitempty"`
	Package    string `yaml:"package,omitempty"`

	FontName string `yaml:"font_name,omitempty"`

	Hooks Hooks `yaml:"hooks"`
}

type Hooks struct {
	After []string
}

func Parse(path string) (Manifest, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Manifest{}, err
	}

	var m Manifest
	if err := yaml.Unmarshal(data, &m); err != nil {
		return Manifest{}, err
	}
	return m, nil
}
