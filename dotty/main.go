package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"dotty/engine"
	"dotty/managers"
	"dotty/manifest"
	"dotty/shell"
	"dotty/ui"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/huh"
)

const PackagesPath = "../packages.yaml"

func setupLogging() (*os.File, error) {
	// Create logs directory
	if err := os.MkdirAll("logs", 0o755); err != nil {
		return nil, err
	}

	// Unique log name: logs/dotty-20250101-120000.log
	filename := filepath.Join("logs", fmt.Sprintf("dotty-%s.log", time.Now().Format("20060102-150405")))
	f, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return nil, err
	}

	handler := slog.NewTextHandler(f, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})
	slog.SetDefault(slog.New(handler))

	return f, nil
}

func main() {
	dryRun := flag.Bool("dry-run", false, "Preview commands without executing")
	yes := flag.Bool("y", false, "Skip confirmation and run all steps")
	flag.Parse()

	logFile, err := setupLogging()
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

	managers := map[string]engine.Manager{
		manifest.ManagerShell:   &managers.Shell{},
		manifest.ManagerDNF:     &managers.Dnf{},
		manifest.ManagerBrew:    &managers.Homebrew{},
		manifest.ManagerCargo:   &managers.Cargo{},
		manifest.ManagerSymlink: &managers.Symlink{},
	}

	sh := shell.New(*dryRun, logFile)
	dotty := engine.New(sh, targetOS, managers)

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
		plannedSteps, planErr = dotty.Plan(packages, planChan)
	}()

	fmt.Println("Analyzing system state...")
	planModel := ui.InitialModel("planning", planChan, totalChecks)
	if _, err := tea.NewProgram(planModel).Run(); err != nil {
		slog.Error("ui error", "error", err)
		fmt.Println("Error running UI:", err)
		os.Exit(1)
	}

	if planErr != nil {
		slog.Error("planning error", "error", err)
		fmt.Printf("Planning failed: %v\n", planErr)
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
		// Prepare options for huh
		options := make([]huh.Option[engine.PlannedStep], len(plannedSteps))
		for i, step := range plannedSteps {
			// Label format: "StepName (Actual Command)"
			label := fmt.Sprintf("%-20s  \x1b[2m%s\x1b[0m", step.Name, step.Command)
			options[i] = huh.NewOption(label, step).Selected(true)
		}

		// Use huh for the checklist
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

	fmt.Println("Installing packages...")
	installChan := make(chan engine.ProgressMsg)
	var installErr error

	go func() {
		installErr = dotty.Execute(stepsToExecute, installChan)
	}()

	installModel := ui.InitialModel(ui.Installing, installChan, len(stepsToExecute))
	if _, err := tea.NewProgram(installModel).Run(); err != nil {
		fmt.Println("Error running UI:", err)
		os.Exit(1)
	}

	if installErr != nil {
		fmt.Printf("\nInstallation had errors: %v\nCheck log for details.\n", installErr)
		os.Exit(1)
	}

	fmt.Println("\nDone! System is ready.")
}
