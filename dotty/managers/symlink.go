package managers

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"dotty/engine"
	"dotty/manifest"
)

type Symlink struct{}

// resolve returns the absolute source and expanded target for a single link
func (m *Symlink) resolve(source, target string) (string, string, error) {
	cwd, err := os.Getwd()
	if err != nil {
		return "", "", err
	}
	repoRoot := filepath.Dir(cwd) // Go up one level from dotty/
	absSource := filepath.Join(repoRoot, source)

	// Expand ~
	home, err := os.UserHomeDir()
	if err != nil {
		return "", "", err
	}

	if strings.HasPrefix(target, "~/") {
		target = filepath.Join(home, target[2:])
	} else if target == "~" {
		target = home
	} else {
		target = os.ExpandEnv(target)
	}

	return absSource, target, nil
}

func (m *Symlink) Exists(ctx engine.Context, instruction manifest.Instruction) bool {
	if len(instruction.Links) == 0 {
		return true // Nothing to link, so "complete"
	}

	for _, link := range instruction.Links {
		absSource, absTarget, err := m.resolve(link.Source, link.Target)
		if err != nil {
			return false
		}

		// Check if target exists
		info, err := os.Lstat(absTarget)
		if err != nil {
			return false
		}

		// Check if it's a symlink
		if info.Mode()&os.ModeSymlink == 0 {
			return false
		}

		// Check destination
		dest, err := os.Readlink(absTarget)
		if err != nil {
			return false
		}

		if filepath.Clean(dest) != filepath.Clean(absSource) {
			return false
		}
	}

	return true
}

func (m *Symlink) GetCommand(ctx engine.Context, instruction manifest.Instruction) string {
	if len(instruction.Links) == 1 {
		return fmt.Sprintf("ln -sf %s %s", instruction.Links[0].Source, instruction.Links[0].Target)
	}

	// summary: "ln -sf [zshrc, gitconfig, ...] -> ~"
	var names []string
	for i, l := range instruction.Links {
		if i >= 3 {
			names = append(names, "...")
			break
		}
		names = append(names, filepath.Base(l.Source))
	}

	// Assuming most targets share a common parent (like ~), but for display we just show the count
	return fmt.Sprintf("ln -sf [%s] (%d files)", strings.Join(names, ", "), len(instruction.Links))
}

func (m *Symlink) Install(ctx engine.Context, instruction manifest.Instruction) error {
	for _, link := range instruction.Links {
		absSource, absTarget, err := m.resolve(link.Source, link.Target)
		if err != nil {
			return err
		}

		// Create Parent Dir
		if err := os.MkdirAll(filepath.Dir(absTarget), 0o755); err != nil {
			return fmt.Errorf("mkdir failed for %s: %w", absTarget, err)
		}

		// Force Remove Existing
		if _, err := os.Lstat(absTarget); err == nil {
			if err := os.Remove(absTarget); err != nil {
				return fmt.Errorf("failed to remove %s: %w", absTarget, err)
			}
		}

		// Link
		if err := os.Symlink(absSource, absTarget); err != nil {
			return fmt.Errorf("symlink failed %s -> %s: %w", absSource, absTarget, err)
		}
	}
	return nil
}
