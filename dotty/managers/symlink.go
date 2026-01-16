package managers

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"dotty/engine"
	"dotty/manifest"
)

type Symlink struct{}

// RequiresPrivilege returns false as symlinks are typically managed in user space.
func (m *Symlink) RequiresPrivilege(instruction manifest.Instruction) bool {
	return false
}

// resolve returns the absolute source and expanded target for a single link
func (m *Symlink) resolve(env engine.Env, source, target string) (string, string, error) {
	cwd, err := env.FS.Getwd()
	if err != nil {
		return "", "", err
	}
	repoRoot := filepath.Dir(cwd)
	absSource := filepath.Join(repoRoot, source)

	home, err := env.FS.UserHomeDir()
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

func (m *Symlink) Exists(ctx context.Context, env engine.Env, instruction manifest.Instruction) bool {
	if len(instruction.Links) == 0 {
		return true // Nothing to link, so "complete"
	}

	for _, link := range instruction.Links {
		if ctx.Err() != nil {
			return false
		}

		absSource, absTarget, err := m.resolve(env, link.Source, link.Target)
		if err != nil {
			return false
		}

		// Check if target exists
		info, err := env.FS.Lstat(absTarget)
		if err != nil {
			return false
		}

		// Check if it's a symlink
		if info.Mode()&os.ModeSymlink == 0 {
			return false
		}

		// Check destination
		dest, err := env.FS.Readlink(absTarget)
		if err != nil {
			return false
		}

		if filepath.Clean(dest) != filepath.Clean(absSource) {
			return false
		}
	}

	return true
}

func (m *Symlink) GetCommand(env engine.Env, instruction manifest.Instruction) string {
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

func (m *Symlink) Install(ctx context.Context, env engine.Env, instruction manifest.Instruction, onLine func(string)) error {
	for _, link := range instruction.Links {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		absSource, absTarget, err := m.resolve(env, link.Source, link.Target)
		if err != nil {
			return err
		}

		if err := env.FS.MkdirAll(filepath.Dir(absTarget), 0o755); err != nil {
			return fmt.Errorf("mkdir failed for %s: %w", absTarget, err)
		}

		if _, err := env.FS.Lstat(absTarget); err == nil {
			if err := env.FS.Remove(absTarget); err != nil {
				return fmt.Errorf("failed to remove %s: %w", absTarget, err)
			}
		}

		if err := env.FS.Symlink(absSource, absTarget); err != nil {
			return fmt.Errorf("symlink failed %s -> %s: %w", absSource, absTarget, err)
		}
	}
	return nil
}
