// Package engine implements the event loop for the Dotty Engine
package engine

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"sync"

	"dotty/manifest"
)

type Status = string

const (
	Checking   Status = "Checking"
	Installing Status = "Installing"
	Done       Status = "Done"
	Failed     Status = "Failed"
)

type Context struct {
	OS     manifest.OSName
	Shell  Shell
	PATH   string
	DryRun bool
}

// Shell defines what the Engine/Managers require from the OS.
type Shell interface {
	Run(name string, args []string, envPath string) error
	Output(name string, args []string, envPath string) (string, error)
}

type Manager interface {
	// Exists checks if the package is already on the system
	Exists(ctx Context, instruction manifest.Instruction) bool

	// GetCommand returns the shell command string that would be executed
	GetCommand(ctx Context, instruction manifest.Instruction) string

	// Install executes the install instruction necessary
	Install(ctx Context, instruction manifest.Instruction) error
}

type Engine struct {
	Ctx      Context
	Managers map[manifest.ManagerName]Manager
}

type PlannedStep struct {
	Name    string
	Command string

	// Instruction must be a pointer to be comparable (slices in structs are not comparable).
	// This is required for UI libraries like 'huh' that track selection by equality.
	Instruction *manifest.Instruction
}

type ProgressMsg struct {
	Name    string
	Status  Status
	Details string
	Done    bool
	Total   int
	Current int
}

func New(shell Shell, targetOS manifest.OSName, managers map[manifest.ManagerName]Manager) Engine {
	initialPATH := os.Getenv("PATH")

	ctx := Context{
		Shell: shell,
		OS:    targetOS,
		PATH:  initialPATH,
	}

	return Engine{
		Ctx:      ctx,
		Managers: managers,
	}
}

// Plan concurrently checks all steps.
func (e *Engine) Plan(m manifest.Manifest, progress chan<- ProgressMsg) ([]PlannedStep, error) {
	type workItem struct {
		Index    int
		StepName string
		Instr    manifest.Instruction
	}
	var work []workItem
	globalIndex := 0
	for _, stage := range m.Stages {
		for _, step := range stage.Steps {
			instr, ok := step.Instructions[e.Ctx.OS]

			// check default
			if !ok {
				instr, ok = step.Instructions[manifest.OSDefault]
			}

			if !ok {
				continue
			}

			work = append(work, workItem{
				Index:    globalIndex,
				StepName: step.Name,
				Instr:    instr,
			})
			globalIndex++
		}
	}

	totalChecks := len(work)

	// use pointers so we can check if a slot was filled (nil = installed).
	results := make([]*PlannedStep, totalChecks)

	jobs := make(chan workItem, totalChecks)
	errChan := make(chan error, totalChecks)
	var wg sync.WaitGroup

	numWorkers := 5
	for range numWorkers {
		wg.Go(func() {
			for item := range jobs {
				progress <- ProgressMsg{Name: item.StepName, Status: "Checking", Details: item.Instr.Manager}

				exists, err := e.checkExistence(item.Instr)
				if err != nil {
					errChan <- fmt.Errorf("step '%s' check failed: %w", item.StepName, err)
					progress <- ProgressMsg{Name: item.StepName, Done: true}
					continue
				}

				if !exists {
					mgr, ok := e.Managers[item.Instr.Manager]
					if !ok {
						errChan <- fmt.Errorf("manager %s not found", item.Instr.Manager)
					} else {
						// Store the result in the correct index
						cmd := mgr.GetCommand(e.Ctx, item.Instr)
						instCopy := item.Instr

						results[item.Index] = &PlannedStep{
							Name:        item.StepName,
							Command:     cmd,
							Instruction: &instCopy,
						}
					}
				}
				progress <- ProgressMsg{Name: item.StepName, Done: true}
			}
		})
	}

	for _, w := range work {
		jobs <- w
	}
	close(jobs)
	wg.Wait()
	close(progress)
	close(errChan)

	var errs []error
	for err := range errChan {
		errs = append(errs, err)
	}
	if len(errs) > 0 {
		return nil, errors.Join(errs...)
	}

	// Compact the results
	var finalSteps []PlannedStep
	for _, res := range results {
		if res != nil {
			finalSteps = append(finalSteps, *res)
		}
	}

	return finalSteps, nil
}

// checkExistence abstracts the logic for checking if a package exists.
func (e *Engine) checkExistence(instr manifest.Instruction) (bool, error) {
	if instr.CheckCmd != "" {
		_, err := e.Ctx.Shell.Output("sh", []string{"-c", instr.CheckCmd}, e.Ctx.PATH)
		return (err == nil), nil
	}

	if instr.Binary != "" {
		_, err := exec.LookPath(instr.Binary)
		return (err == nil), nil
	}

	if mgr, ok := e.Managers[instr.Manager]; ok {
		return mgr.Exists(e.Ctx, instr), nil
	}

	return false, fmt.Errorf("no manager found for %s", instr.Manager)
}

// Execute runs the steps sequentially (installations are risky to run in parallel due to lock files)
// but reports progress to the UI channel.
func (e *Engine) Execute(steps []PlannedStep, progress chan<- ProgressMsg) error {
	defer close(progress)

	for i, step := range steps {
		instruction := *step.Instruction
		manager := e.Managers[instruction.Manager]

		if len(instruction.Hooks.Before) > 0 {
			progress <- ProgressMsg{
				Name:    step.Name,
				Status:  "Running Pre-hooks",
				Details: "Setting up dependencies...",
				Current: i + 1,
				Total:   len(steps),
			}

			for _, cmd := range instruction.Hooks.Before {
				// Use the shell to run the hook
				if err := e.Ctx.Shell.Run("sh", []string{"-c", cmd}, e.Ctx.PATH); err != nil {
					return fmt.Errorf("step '%s' pre-hook failed: %w", step.Name, err)
				}
			}
		}

		progress <- ProgressMsg{
			Name:    step.Name,
			Status:  "Installing",
			Details: instruction.Manager,
			Current: i + 1,
			Total:   len(steps),
		}

		if err := manager.Install(e.Ctx, instruction); err != nil {
			slog.Error("install failed", "step", step.Name, "error", err)
			return fmt.Errorf("step '%s' failed: %w", step.Name, err)
		}

		if len(instruction.Hooks.After) > 0 {
			progress <- ProgressMsg{Name: step.Name, Status: "Running Hooks"}
			for _, cmd := range instruction.Hooks.After {
				if err := e.Ctx.Shell.Run("sh", []string{"-c", cmd}, e.Ctx.PATH); err != nil {
					return fmt.Errorf("step '%s' hook failed: %w", step.Name, err)
				}
			}
		}
	}
	return nil
}
