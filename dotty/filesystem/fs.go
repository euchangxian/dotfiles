// Package filesystem provides abstraction over the Real FS, and enables DryRun
package filesystem

import (
	"fmt"
	"os"
)

// Real implements FileSystem for actual OS operations.
type Real struct{}

func (f Real) Symlink(oldname, newname string) error {
	return os.Symlink(oldname, newname)
}

func (f Real) Remove(name string) error {
	return os.Remove(name)
}

func (f Real) MkdirAll(path string, perm os.FileMode) error {
	return os.MkdirAll(path, perm)
}

func (f Real) Lstat(name string) (os.FileInfo, error) {
	return os.Lstat(name)
}

func (f Real) Readlink(name string) (string, error) {
	return os.Readlink(name)
}

func (f Real) UserHomeDir() (string, error) {
	return os.UserHomeDir()
}

func (f Real) Getwd() (string, error) {
	return os.Getwd()
}

// DryRun implements FileSystem but only logs intent.
type DryRun struct {
	Real // Embed for read-only operations (Lstat, Getwd, etc.)
}

func (f DryRun) Symlink(old, new string) error {
	fmt.Printf("\x1b[36m[FS]\x1b[0m Would symlink: %s -> %s\n", old, new)
	return nil
}

func (f DryRun) Remove(name string) error {
	fmt.Printf("\x1b[36m[FS]\x1b[0m Would remove: %s\n", name)
	return nil
}

func (f DryRun) MkdirAll(path string, perm os.FileMode) error {
	fmt.Printf("\x1b[36m[FS]\x1b[0m Would mkdir: %s\n", path)
	return nil
}
