// Package ui provides the user interface for the Dotty Engine.
package ui

import (
	"fmt"

	"dotty/engine"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type mode = string

const (
	Planning   mode = "planning"
	Installing mode = "installing"
	Done       mode = "done"
)

var (
	subtleStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("241"))
	itemStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("255")).Bold(true)
	statusStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("63"))
	errStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("196"))
)

type model struct {
	mode     mode
	progress progress.Model
	spinner  spinner.Model

	// Data
	currentName string
	status      string
	totalItems  int
	completed   int

	// Communication
	progressChan <-chan engine.ProgressMsg
	err          error
}

type doneMsg struct{}

func InitialModel(mode string, ch <-chan engine.ProgressMsg, totalExpected int) model {
	p := progress.New(
		progress.WithDefaultGradient(),
		progress.WithWidth(40),
		progress.WithoutPercentage(),
	)
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = statusStyle

	return model{
		mode:         mode,
		progress:     p,
		spinner:      s,
		progressChan: ch,
		totalItems:   totalExpected,
		status:       "Initializing...",
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		listenForUpdates(m.progressChan),
		m.spinner.Tick,
	)
}

// Command to listen to the channel
func listenForUpdates(ch <-chan engine.ProgressMsg) tea.Cmd {
	return func() tea.Msg {
		msg, ok := <-ch
		if !ok {
			return doneMsg{}
		}
		return msg
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.Type == tea.KeyCtrlC {
			return m, tea.Quit
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case engine.ProgressMsg:
		// Update State
		m.currentName = msg.Name

		if msg.Status != "" {
			m.status = msg.Status
		}

		if m.mode == Planning {
			// In planning, we count how many checks finished
			if msg.Done {
				m.completed++
			}
		} else {
			// In installing, the engine sends explicit Count/Total
			if msg.Current > 0 {
				m.completed = msg.Current
				m.totalItems = msg.Total
			}
		}

		// Calculate percentage to animate status bar
		pct := 0.0
		if m.totalItems > 0 {
			pct = float64(m.completed) / float64(m.totalItems)
		}

		cmd := m.progress.SetPercent(pct)
		return m, tea.Batch(cmd, listenForUpdates(m.progressChan))

	case progress.FrameMsg:
		newModel, cmd := m.progress.Update(msg)
		if newModel, ok := newModel.(progress.Model); ok {
			m.progress = newModel
		}
		return m, cmd

	case doneMsg:
		m.mode = Done
		return m, tea.Quit
	}

	return m, nil
}

func (m model) View() string {
	if m.err != nil {
		return errStyle.Render(fmt.Sprintf("Error: %v", m.err)) + "\n"
	}
	if m.mode == Done {
		return "" // Clear screen or print nothing when done, main() handles summary
	}

	spin := m.spinner.View() + " "
	task := itemStyle.Render(m.currentName)
	stat := subtleStyle.Render(m.status)

	prog := m.progress.View()

	header := fmt.Sprintf("%s %s %s", spin, task, stat)
	count := fmt.Sprintf("%d / %d", m.completed, m.totalItems)

	return fmt.Sprintf("\n%s\n%s %s\n\n", header, prog, count)
}
