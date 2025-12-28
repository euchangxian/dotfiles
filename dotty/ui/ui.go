// Package ui provides the user interface for the Dotty Engine.
package ui

import (
	"fmt"
	"strings"

	"dotty/engine"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type mode = string

const (
	ModePlanning   mode = "planning"
	ModeInstalling mode = "installing"
	ModeDone       mode = "done"
)

var (
	SubtleStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("241"))            // Gray
	ItemStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("255")).Bold(true) // White
	StatusStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("63"))             // Blue
	ErrStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("196"))            // Red
	LogStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("36"))             // Cyan
)

type Model struct {
	mode     mode
	progress progress.Model
	spinner  spinner.Model

	// Data
	currentStage string
	currentName  string
	status       string
	totalItems   int
	completed    int
	found        int
	missing      int
	Results      []engine.ProgressMsg

	// Communication
	progressChan <-chan engine.ProgressMsg
	err          error

	history    []string
	lastOutput string
}

type doneMsg struct{}

func InitialModel(mode string, ch <-chan engine.ProgressMsg, totalExpected int) Model {
	p := progress.New(
		progress.WithDefaultGradient(),
		progress.WithWidth(40),
		progress.WithoutPercentage(),
	)
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = StatusStyle

	return Model{
		mode:         mode,
		progress:     p,
		spinner:      s,
		progressChan: ch,
		totalItems:   totalExpected,
		status:       "Initializing...",
	}
}

func (m Model) Init() tea.Cmd {
	return tea.Batch(
		listenForUpdates(m.progressChan),
		m.spinner.Tick,
	)
}

func listenForUpdates(ch <-chan engine.ProgressMsg) tea.Cmd {
	return func() tea.Msg {
		msg, ok := <-ch
		if !ok {
			return doneMsg{}
		}
		return msg
	}
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		return m, m.handleKey(msg)
	case spinner.TickMsg:
		return m.handleSpinnerTick(msg)
	case engine.ProgressMsg:
		return m.handleProgress(msg)
	case progress.FrameMsg:
		return m.handleProgressFrame(msg)
	case doneMsg:
		m.mode = ModeDone
		return m, tea.Quit
	}
	return m, nil
}

// handleKey handles keyboard input
func (m Model) handleKey(msg tea.KeyMsg) tea.Cmd {
	if msg.Type == tea.KeyCtrlC {
		return tea.Quit
	}
	return nil
}

// handleSpinnerTick handles spinner animation
func (m Model) handleSpinnerTick(msg spinner.TickMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	m.spinner, cmd = m.spinner.Update(msg)
	return m, cmd
}

// handleProgressFrame handles the progress bar animation frames
func (m Model) handleProgressFrame(msg progress.FrameMsg) (tea.Model, tea.Cmd) {
	newModel, cmd := m.progress.Update(msg)
	if newModel, ok := newModel.(progress.Model); ok {
		m.progress = newModel
	}
	return m, cmd
}

// handleProgress contains the core logic for processing engine updates
func (m Model) handleProgress(msg engine.ProgressMsg) (tea.Model, tea.Cmd) {
	m.currentName = msg.Name
	m.lastOutput = msg.Details // used for the log peek

	if msg.Stage != "" {
		m.currentStage = msg.Stage
	}

	if m.mode == ModePlanning {
		m.processPlanningUpdate(msg)
	} else {
		m.processInstallingUpdate(msg)
	}

	pct := 0.0
	if m.totalItems > 0 {
		pct = float64(m.completed) / float64(m.totalItems)
	}
	progressCmd := m.progress.SetPercent(pct)

	return m, tea.Batch(progressCmd, listenForUpdates(m.progressChan))
}

func (m *Model) processPlanningUpdate(msg engine.ProgressMsg) {
	if !msg.Done() {
		return
	}
	m.completed++
	if msg.Found {
		m.found++
	} else {
		m.missing++
	}
}

func (m *Model) processInstallingUpdate(msg engine.ProgressMsg) {
	if msg.Current > 0 {
		m.completed = msg.Current
		m.totalItems = msg.Total
	}

	if msg.Done() {
		m.Results = append(m.Results, msg)

		symbol := "\x1b[32m✓\x1b[0m"
		if msg.Error != nil {
			symbol = "\x1b[31m✖\x1b[0m"
		}
		m.history = append(m.history, fmt.Sprintf("%s %s", symbol, m.currentName))
		if len(m.history) > 3 {
			m.history = m.history[1:]
		}
	}
}

func (m Model) View() string {
	if m.err != nil {
		return ErrStyle.Render(fmt.Sprintf("Error: %v", m.err)) + "\n"
	}
	if m.mode == ModeDone {
		return ""
	}

	var content string
	switch m.mode {
	case ModePlanning:
		content = m.renderPlanning()
	case ModeInstalling:
		content = m.renderInstalling()
	}

	return "\n" + content + "\n"
}

func (m Model) renderPlanning() string {
	header := fmt.Sprintf("%s Analyzing... %s", m.spinner.View(), ItemStyle.Render(m.currentName))
	stats := fmt.Sprintf("Found: %d | Missing: %d", m.found, m.missing)
	return lipgloss.JoinVertical(lipgloss.Left,
		header,
		m.progress.View(),
		stats,
	)
}

func (m Model) renderInstalling() string {
	history := strings.Join(m.history, "\n")
	activeTask := fmt.Sprintf("%s %s", m.spinner.View(), ItemStyle.Render(m.currentName))
	logPeek := ""
	if m.lastOutput != "" {
		arrow := SubtleStyle.Render("  ↳ ")
		text := LogStyle.Render(m.lastOutput)
		logPeek = arrow + text
	}
	progressRow := fmt.Sprintf("%s %d / %d", m.progress.View(), m.completed, m.totalItems)
	return lipgloss.JoinVertical(lipgloss.Left,
		history,
		activeTask,
		logPeek,
		progressRow,
	)
}
