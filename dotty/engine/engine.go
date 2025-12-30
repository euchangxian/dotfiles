// Package engine implements the event loop for the Dotty Engine
package engine

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"

	"dotty/filesystem"
	"dotty/manifest"

	"golang.org/x/sync/errgroup"
)

type Status = string

const (
	StatusChecking   Status = "Checking"
	StatusInstalling Status = "Installing"
	StatusDone       Status = "Done"
	StatusFailed     Status = "Failed"
)

type FileSystem interface {
	Symlink(oldname, newname string) error
	Remove(name string) error
	MkdirAll(path string, perm os.FileMode) error
	Lstat(name string) (os.FileInfo, error)
	Readlink(name string) (string, error)
	UserHomeDir() (string, error)
	Getwd() (string, error)
}

// Shell defines what the Engine/Managers require from the OS.
type Shell interface {
	Run(ctx context.Context, name string, args []string, envPath string, onLine func(string)) error
	Output(ctx context.Context, name string, args []string, envPath string) (string, error)
}

type Env struct {
	OS     manifest.OSName
	Shell  Shell
	FS     FileSystem
	PATH   string
	DryRun bool
}

type Manager interface {
	// Exists checks if the package is already on the system
	Exists(ctx context.Context, env Env, instruction manifest.Instruction) bool

	// GetCommand returns the shell command string that would be executed
	GetCommand(env Env, instruction manifest.Instruction) string

	// Install executes the install instruction necessary
	Install(ctx context.Context, env Env, instruction manifest.Instruction, onLine func(string)) error

	// RequiresPrivilege returns true if the manager or specific instruction needs root access.
	RequiresPrivilege(instruction manifest.Instruction) bool
}

type Engine struct {
	Env      Env
	Managers map[manifest.ManagerName]Manager
}

type PlannedStep struct {
	StageName string
	Name      string
	Command   string

	// Instruction must be a pointer to be comparable (slices in structs are not comparable).
	// This is required for UI libraries like 'huh' that track selection by equality.
	Instruction *manifest.Instruction
}

type ProgressMsg struct {
	Stage   string
	Name    string
	Status  Status
	Details string
	Found   bool
	Total   int
	Current int
	Error   error
}

func (m *ProgressMsg) Done() bool {
	return m.Status == StatusDone || m.Status == StatusFailed
}

func New(shell Shell, targetOS manifest.OSName, managers map[manifest.ManagerName]Manager, dryRun bool) Engine {
	initialPATH := os.Getenv("PATH")

	var fs FileSystem = filesystem.Real{}
	if dryRun {
		fs = filesystem.DryRun{}
	}

	env := Env{
		Shell:  shell,
		OS:     targetOS,
		FS:     fs,
		PATH:   initialPATH,
		DryRun: dryRun,
	}

	return Engine{
		Env:      env,
		Managers: managers,
	}
}

// Plan concurrently checks all steps.
func (e *Engine) Plan(ctx context.Context, m manifest.Manifest, progress chan<- ProgressMsg) ([]PlannedStep, error) {
	type workItem struct {
		Index     int
		StageName string
		StepName  string
		Instr     manifest.Instruction
	}
	var work []workItem
	globalIndex := 0
	for _, stage := range m.Stages {
		for _, step := range stage.Steps {
			instr, ok := step.Instructions[e.Env.OS]

			// check default
			if !ok {
				instr, ok = step.Instructions[manifest.OSDefault]
			}

			if !ok {
				continue
			}

			work = append(work, workItem{
				Index:     globalIndex,
				StageName: stage.Name,
				StepName:  step.Name,
				Instr:     instr,
			})
			globalIndex++
		}
	}

	totalChecks := len(work)
	results := make([]*PlannedStep, totalChecks)
	jobs := make(chan workItem, totalChecks)
	g, gCtx := errgroup.WithContext(ctx)

	numWorkers := 5
	for range numWorkers {
		g.Go(func() error {
			for item := range jobs {
				if gCtx.Err() != nil {
					return gCtx.Err()
				}
				progress <- ProgressMsg{
					Stage:   item.StageName,
					Name:    item.StepName,
					Status:  StatusChecking,
					Details: item.Instr.Manager,
				}

				exists, err := e.checkExistence(gCtx, item.Instr)
				if err != nil {
					return err
				}

				if !exists {
					if mgr, ok := e.Managers[item.Instr.Manager]; ok {
						results[item.Index] = &PlannedStep{
							StageName:   item.StageName,
							Name:        item.StepName,
							Command:     mgr.GetCommand(e.Env, item.Instr),
							Instruction: &item.Instr,
						}
					}
				}

				progress <- ProgressMsg{
					Stage:  item.StageName,
					Name:   item.StepName,
					Status: StatusDone,
					Found:  exists,
				}
			}
			return nil
		})
	}

	for _, w := range work {
		jobs <- w
	}
	close(jobs)

	if err := g.Wait(); err != nil {
		progress <- ProgressMsg{Status: StatusFailed, Error: err}
		return nil, err
	}

	var finalSteps []PlannedStep
	for _, res := range results {
		if res != nil {
			finalSteps = append(finalSteps, *res)
		}
	}

	return finalSteps, nil
}

// checkExistence abstracts the logic for checking if a package exists.
func (e *Engine) checkExistence(ctx context.Context, instr manifest.Instruction) (bool, error) {
	if instr.CheckCmd != "" {
		_, err := e.Env.Shell.Output(ctx, "sh", []string{"-c", instr.CheckCmd}, e.Env.PATH)
		return (err == nil), nil
	}

	if instr.Binary != "" {
		_, err := exec.LookPath(instr.Binary)
		return (err == nil), nil
	}

	if mgr, ok := e.Managers[instr.Manager]; ok {
		return mgr.Exists(ctx, e.Env, instr), nil
	}

	return false, fmt.Errorf("no manager found for %s", instr.Manager)
}

// Execute runs the steps sequentially (installations are risky to run in parallel due to lock files)
// but reports progress to the UI channel.
func (e *Engine) Execute(ctx context.Context, steps []PlannedStep, progress chan<- ProgressMsg) error {
	totalSteps := len(steps)
	for i, step := range steps {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		instruction := *step.Instruction
		manager := e.Managers[instruction.Manager]

		notify := func(line string) {
			progress <- ProgressMsg{
				Name:    step.Name,
				Status:  StatusInstalling,
				Details: line,
				Current: i + 1,
				Total:   totalSteps,
			}
		}

		if len(instruction.Hooks.Before) > 0 {
			progress <- ProgressMsg{
				Name:    step.Name,
				Status:  "Running Pre-hooks",
				Details: "Setting up dependencies...",
				Current: i + 1,
				Total:   totalSteps,
			}

			for _, cmd := range instruction.Hooks.Before {
				if err := e.Env.Shell.Run(ctx, "sh", []string{"-c", cmd}, e.Env.PATH, notify); err != nil {
					return fmt.Errorf("step '%s' pre-hook failed: %w", step.Name, err)
				}
			}
		}

		progress <- ProgressMsg{
			Name:    step.Name,
			Status:  StatusInstalling,
			Details: instruction.Manager,
			Current: i + 1,
			Total:   totalSteps,
		}

		if err := manager.Install(ctx, e.Env, instruction, notify); err != nil {
			slog.Error("install failed", "step", step.Name, "error", err)
			progress <- ProgressMsg{
				Name:    step.Name,
				Status:  StatusFailed,
				Error:   err,
				Current: i + 1,
				Total:   totalSteps,
			}
			return fmt.Errorf("step '%s' failed: %w", step.Name, err)
		}

		if len(instruction.Hooks.After) > 0 {
			progress <- ProgressMsg{
				Name:    step.Name,
				Status:  "Running Post-hooks",
				Details: "",
				Current: i + 1,
				Total:   totalSteps,
			}
			for _, cmd := range instruction.Hooks.After {
				if err := e.Env.Shell.Run(ctx, "sh", []string{"-c", cmd}, e.Env.PATH, notify); err != nil {
					return fmt.Errorf("step '%s' post-hook failed: %w", step.Name, err)
				}
			}
		}

		progress <- ProgressMsg{
			Name:    step.Name,
			Status:  StatusDone,
			Current: i + 1,
			Total:   totalSteps,
		}
	}
	return nil
}
