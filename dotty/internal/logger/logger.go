package logger

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"time"
)

// Setup creates a unique log file and returns it along with an error.
func Setup() (*os.File, error) {
	if err := os.MkdirAll("logs", 0o755); err != nil {
		return nil, err
	}

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
