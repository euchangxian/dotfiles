package managers

import (
	"dotty/engine"
	"dotty/manifest"
)

var registry = make(map[manifest.ManagerName]engine.Manager)

func Register(name string, m engine.Manager) {
	registry[name] = m
}

func GetRegistry() map[manifest.ManagerName]engine.Manager {
	return registry
}
