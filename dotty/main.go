package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"strings"

	"dotty/engine"
	"dotty/internal/logger"
	"dotty/managers"
	"dotty/manifest"
	"dotty/shell"
	"dotty/ui"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/huh"
)

const PackagesPath = "../packages.yaml"

func init() {
	managers.Register(manifest.ManagerShell, managers.NewShell())
	managers.Register(manifest.ManagerDNF, managers.NewDnf())
	managers.Register(manifest.ManagerBrew, managers.NewHomebrew())
	managers.Register(manifest.ManagerCargo, managers.NewCargo())
	managers.Register(manifest.ManagerSymlink, &managers.Symlink{})
}

func ensureSudo(steps []engine.PlannedStep, managers map[manifest.ManagerName]engine.Manager) {
	needsSudo := false
	for _, step := range steps {
		mgr, ok := managers[step.Instruction.Manager]
		if ok && mgr.RequiresPrivilege(*step.Instruction) {
			needsSudo = true
			break
		}

		// Custom shell commands
		if strings.Contains(step.Instruction.InstallCmd, "sudo") {
			needsSudo = true
			break
		}

		for _, h := range step.Instruction.Hooks.Before {
			if strings.Contains(h, "sudo") {
				needsSudo = true
				break
			}
		}
		for _, h := range step.Instruction.Hooks.After {
			if strings.Contains(h, "sudo") {
				needsSudo = true
				break
			}
		}
	}

	if needsSudo {
		fmt.Println("Some steps require root access. Checking permissions...")
		cmd := exec.Command("sudo", "-v")
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Println("Sudo authentication failed. Exiting.")
			os.Exit(1)
		}
		fmt.Println("Permissions granted.")
	}
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	dryRun := flag.Bool("dry-run", false, "Preview commands without executing")
	yes := flag.Bool("y", false, "Skip confirmation and run all steps")
	flag.Parse()

	logFile, err := logger.Setup()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to setup logging: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		if err := logFile.Close(); err != nil {
			fmt.Fprintf(os.Stderr, "failed to close %v: %v\n", logFile.Name(), err)
			os.Exit(1)
		}
	}()

	var targetOS manifest.OSName
	switch runtime.GOOS {
	case "darwin":
		targetOS = manifest.OSMac
	case "linux":
		targetOS = manifest.OSFedora
	default:
		slog.Error("unsupported os", "os", runtime.GOOS)
		fmt.Printf("Unsupported OS: %s\n", runtime.GOOS)
		os.Exit(1)
	}

	slog.Info("starting dotty", "os", targetOS, "dry-run", *dryRun)

	packages, err := manifest.Parse(PackagesPath)
	if err != nil {
		slog.Error("parse error", "error", err, "PackagesPath", PackagesPath)
		fmt.Printf("Error parsing packages: %v\n", err)
		os.Exit(1)
	}

	sh := shell.New(*dryRun, logFile)
	dotty := engine.New(sh, targetOS, managers.GetRegistry(), *dryRun)

	// Calculate total tasks for progress bar
	totalChecks := 0
	for _, s := range packages.Stages {
		for _, step := range s.Steps {
			if _, ok := step.Instructions[targetOS]; ok {
				totalChecks++
			} else if _, ok := step.Instructions[manifest.OSDefault]; ok {
				totalChecks++
			}
		}
	}

	planChan := make(chan engine.ProgressMsg)
	var plannedSteps []engine.PlannedStep
	var planErr error
	go func() {
		defer close(planChan)
		plannedSteps, planErr = dotty.Plan(ctx, packages, planChan)
	}()

	fmt.Println("Analyzing system state...")
	planModel := ui.InitialModel("planning", planChan, totalChecks)
	if _, err := tea.NewProgram(planModel).Run(); err != nil {
		slog.Error("ui error", "error", err)
		fmt.Println("Error running UI:", err)
		os.Exit(1)
	}

	if planErr != nil {
		fmt.Printf("Planning failed: %v\n", planErr) // Correct variable here
		os.Exit(1)
	}

	if len(plannedSteps) == 0 {
		fmt.Println("Everything is up to date!")
		return
	}

	var stepsToExecute []engine.PlannedStep
	if *yes {
		stepsToExecute = plannedSteps
	} else {
		options := make([]huh.Option[engine.PlannedStep], len(plannedSteps))
		for i, step := range plannedSteps {
			hookParts := []string{}
			if len(step.Instruction.Hooks.Before) > 0 {
				hookParts = append(hookParts, "+pre")
			}
			if len(step.Instruction.Hooks.After) > 0 {
				hookParts = append(hookParts, "+post")
			}

			hookTip := ""
			if len(hookParts) > 0 {
				// yellow/amber
				hookTip = fmt.Sprintf(" \x1b[33m[%s]\x1b[0m", strings.Join(hookParts, "/"))
			}

			// truncate if command is too long for brevity
			displayCmd := step.Command
			if len(displayCmd) > 40 {
				displayCmd = displayCmd[:37] + "..."
			}

			label := fmt.Sprintf(
				"\x1b[2m[%s]\x1b[0m %-15s%s \x1b[2;37m| %s\x1b[0m",
				strings.ToUpper(step.StageName),
				step.Name,
				hookTip,
				displayCmd,
			)

			options[i] = huh.NewOption(label, step).Selected(true)
		}

		form := huh.NewForm(
			huh.NewGroup(
				huh.NewMultiSelect[engine.PlannedStep]().
					Title("Proposed Changes").
					Description("Select the items you want to install (Space to toggle, Enter to confirm)").
					Options(options...).
					Value(&stepsToExecute),
			),
		)

		err := form.Run()
		if err != nil {
			// Handle user cancellation (Ctrl+C usually returns err)
			slog.Info("operation cancelled by user")
			fmt.Println("Cancelled.")
			os.Exit(0)
		}
	}

	if len(stepsToExecute) == 0 {
		fmt.Println("No steps selected.")
		return
	}

	if *dryRun {
		fmt.Println("Dry-run complete. No changes made.")
		return
	}

	ensureSudo(stepsToExecute, managers.GetRegistry())

	fmt.Println("Installing packages...")
	installChan := make(chan engine.ProgressMsg)
	installModel := ui.InitialModel(ui.ModeInstalling, installChan, len(stepsToExecute))
	go func() {
		defer close(installChan)
		_ = dotty.Execute(ctx, stepsToExecute, installChan)
	}()
	m, err := tea.NewProgram(installModel).Run()
	if err != nil {
		fmt.Println("Error running UI:", err)
		os.Exit(1)
	}

	finalModel := m.(ui.Model)
	hasError := false
	fmt.Println("\n" + ui.ItemStyle.Render("Installation Summary:"))
	for _, res := range finalModel.Results {
		if res.Error == nil {
			fmt.Printf("  \x1b[32m✓\x1b[0m %-15s\n", res.Name)
		} else {
			hasError = true
			fmt.Printf("  \x1b[31m✖\x1b[0m %-15s %s\n", res.Name, ui.SubtleStyle.Render(res.Error.Error()))
		}
	}

	if hasError {
		fmt.Println(ui.ErrStyle.Render("\n ✖ Installation encountered errors:"))
	} else {
		fmt.Println(ui.StatusStyle.Render("\n ✔ System configuration complete!"))
	}
}
