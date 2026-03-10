package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	"go.uber.org/zap"
)

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		os.Stderr.WriteString("failed to initialize logger\n")
		os.Exit(1)
	}
	defer func() {
		_ = logger.Sync()
	}()
	pluginsDir := flag.String("plugins-dir", "plugins", "Directory to discover Lua plugins")
	pluginArg := flag.String("plugin", "", "Plugin path or discovered plugin name")
	listPlugins := flag.Bool("list-plugins", false, "List discovered plugins and exit")
	flag.Parse()
	discoveredPaths, err := discoverPlugins(*pluginsDir)
	if err != nil {
		logger.Fatal("failed to discover plugins", zap.String("plugins_dir", *pluginsDir), zap.Error(err))
		os.Exit(1)
	}
	catalog := loadPluginCatalog(discoveredPaths)
	if *listPlugins {
		if len(catalog) == 0 {
			fmt.Println("No plugins discovered.")
			return
		}
		fmt.Println("Discovered plugins:")
		for _, p := range catalog {
			if p.Err != nil {
				fmt.Printf("- %s (invalid: %v)\n", p.Path, p.Err)
				continue
			}
			fmt.Printf("- %s v%s (%s)\n", p.Meta.Name, p.Meta.Version, p.Path)
			if p.Meta.Description != "" {
				fmt.Printf("  %s\n", p.Meta.Description)
			}
		}
		return
	}
	selectedPlugin, err := resolvePlugin(*pluginArg, catalog)
	if err != nil {
		logger.Error("failed to resolve plugin", zap.String("selection", *pluginArg), zap.Error(err))
		valid := validPlugins(catalog)
		if len(valid) > 0 {
			logger.Info("available plugins")
			for _, p := range valid {
				logger.Info("plugin", zap.String("name", p.Meta.Name), zap.String("path", p.Path))
			}
		}
		os.Exit(1)
	}
	absPluginPath, err := filepath.Abs(selectedPlugin)
	if err != nil {
		logger.Fatal("failed to resolve plugin path", zap.String("plugin", selectedPlugin), zap.Error(err))
		os.Exit(1)
	}
	plugin, err := loadPlugin(absPluginPath)
	if err != nil {
		logger.Fatal("failed to load plugin", zap.String("plugin_path", absPluginPath), zap.Error(err))
		os.Exit(1)
	}
	defer plugin.Close()
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(interrupt)
	stop := make(chan struct{})
	go func() {
		<-interrupt
		close(stop)
	}()
	logger.Info("loaded plugin", zap.String("name", plugin.meta.Name), zap.String("version", plugin.meta.Version))
	logger.Info("render settings", zap.Int("fps", clampFPS(60)), zap.Float64("duration", 0))
	if err := runAnimation(plugin, 60, 0, stop); err != nil {
		logger.Fatal("animation failed", zap.Error(err))
		os.Exit(1)
	}
}
