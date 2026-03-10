package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type discoveredPlugin struct {
	Path string
	Meta pluginMetadata
	Err  error
}

func discoverPlugins(dir string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	plugins := make([]string, 0)
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		if strings.EqualFold(filepath.Ext(entry.Name()), ".lua") {
			plugins = append(plugins, filepath.Join(dir, entry.Name()))
		}
	}
	sort.Strings(plugins)
	return plugins, nil
}

func loadPluginCatalog(paths []string) []discoveredPlugin {
	catalog := make([]discoveredPlugin, 0, len(paths))
	for _, path := range paths {
		item := discoveredPlugin{Path: path}
		plugin, err := loadPlugin(path)
		if err != nil {
			item.Err = err
			catalog = append(catalog, item)
			continue
		}
		item.Meta = plugin.meta
		plugin.Close()
		catalog = append(catalog, item)
	}
	return catalog
}

func validPlugins(catalog []discoveredPlugin) []discoveredPlugin {
	valid := make([]discoveredPlugin, 0, len(catalog))
	for _, p := range catalog {
		if p.Err == nil {
			valid = append(valid, p)
		}
	}
	return valid
}

func resolvePlugin(selection string, catalog []discoveredPlugin) (string, error) {
	valid := validPlugins(catalog)
	if selection == "" {
		if len(valid) == 0 {
			return "", fmt.Errorf("no Lua plugins found")
		}
		return valid[0].Path, nil
	}
	if info, err := os.Stat(selection); err == nil && !info.IsDir() {
		return selection, nil
	}
	normalized := strings.TrimSpace(selection)
	for _, item := range valid {
		name := filepath.Base(item.Path)
		base := strings.TrimSuffix(name, filepath.Ext(name))
		if normalized == name || normalized == base || strings.EqualFold(normalized, item.Meta.Name) {
			return item.Path, nil
		}
	}
	return "", fmt.Errorf("plugin %q not found", selection)
}
