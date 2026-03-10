package main

import (
	"fmt"
	"os"
	"strings"
	"time"
	"unicode/utf8"

	lua "github.com/yuin/gopher-lua"
	"golang.org/x/term"
)

type (
	cell struct {
		ch    rune
		color string
	}

	screenBuffer struct {
		width  int
		height int
		cells  []cell
	}

	drawCommand struct {
		x     int
		y     int
		ch    rune
		color string
	}

	pluginMetadata struct {
		Name        string
		Version     string
		Author      string
		Description string
	}

	luaPlugin struct {
		state *lua.LState
		init  *lua.LFunction
		paint *lua.LFunction
		meta  pluginMetadata
	}
)

func newScreenBuffer(width, height int) *screenBuffer {
	b := &screenBuffer{width: width, height: height, cells: make([]cell, width*height)}
	b.Clear()
	return b
}

func (b *screenBuffer) Resize(width, height int) {
	if b.width == width && b.height == height {
		return
	}
	b.width = width
	b.height = height
	b.cells = make([]cell, width*height)
	b.Clear()
}

func (b *screenBuffer) Clear() {
	for i := range b.cells {
		b.cells[i] = cell{ch: ' ', color: ""}
	}
}

func (b *screenBuffer) Set(x, y int, ch rune, color string) {
	if x < 0 || y < 0 || x >= b.width || y >= b.height {
		return
	}
	b.cells[y*b.width+x] = cell{ch: ch, color: color}
}

func (b *screenBuffer) Apply(commands []drawCommand) {
	for _, c := range commands {
		b.Set(c.x, c.y, c.ch, c.color)
	}
}

func (b *screenBuffer) String() string {
	var sb strings.Builder
	sb.Grow((b.width + 1) * b.height * 4)
	lastColor := ""
	for y := 0; y < b.height; y++ {
		for x := 0; x < b.width; x++ {
			c := b.cells[y*b.width+x]
			if c.color != lastColor {
				if c.color == "" {
					sb.WriteString("\x1b[0m")
				} else {
					sb.WriteString("\x1b[")
					sb.WriteString(c.color)
					sb.WriteString("m")
				}
				lastColor = c.color
			}
			sb.WriteRune(c.ch)
		}
		sb.WriteString("\x1b[0m")
		lastColor = ""
		if y != b.height-1 {
			sb.WriteByte('\n')
		}
	}
	return sb.String()
}

func readMetaField(meta *lua.LTable, key string) string {
	v := meta.RawGetString(key)
	if v.Type() == lua.LTNil {
		return ""
	}
	return strings.TrimSpace(v.String())
}

func parsePluginMetadata(pluginTable *lua.LTable) (pluginMetadata, error) {
	metaVal := pluginTable.RawGetString("meta")
	metaTable, ok := metaVal.(*lua.LTable)
	if !ok {
		return pluginMetadata{}, fmt.Errorf("plugin.meta table is required")
	}
	name := readMetaField(metaTable, "name")
	version := readMetaField(metaTable, "version")
	if name == "" {
		return pluginMetadata{}, fmt.Errorf("plugin.meta.name is required")
	}
	if version == "" {
		return pluginMetadata{}, fmt.Errorf("plugin.meta.version is required")
	}
	return pluginMetadata{
		Name:        name,
		Version:     version,
		Author:      readMetaField(metaTable, "author"),
		Description: readMetaField(metaTable, "description"),
	}, nil
}

func loadPlugin(path string) (*luaPlugin, error) {
	L := lua.NewState()
	if err := L.DoFile(path); err != nil {
		L.Close()
		return nil, fmt.Errorf("load plugin: %w", err)
	}
	pluginVal := L.GetGlobal("plugin")
	pluginTable, ok := pluginVal.(*lua.LTable)
	if !ok {
		L.Close()
		return nil, fmt.Errorf("plugin file must define global table 'plugin'")
	}
	meta, err := parsePluginMetadata(pluginTable)
	if err != nil {
		L.Close()
		return nil, err
	}
	paintVal := pluginTable.RawGetString("paint")
	paintFn, ok := paintVal.(*lua.LFunction)
	if !ok {
		L.Close()
		return nil, fmt.Errorf("plugin.paint function is required")
	}
	var initFn *lua.LFunction
	if fn, ok := pluginTable.RawGetString("init").(*lua.LFunction); ok {
		initFn = fn
	}
	return &luaPlugin{state: L, init: initFn, paint: paintFn, meta: meta}, nil
}

func (p *luaPlugin) Close() {
	p.state.Close()
}

func luaContextTable(L *lua.LState, width, height, frame int, elapsed float64) *lua.LTable {
	tbl := L.NewTable()
	tbl.RawSetString("width", lua.LNumber(width))
	tbl.RawSetString("height", lua.LNumber(height))
	tbl.RawSetString("frame", lua.LNumber(frame))
	tbl.RawSetString("time", lua.LNumber(elapsed))
	return tbl
}

func (p *luaPlugin) Init(width, height int) error {
	if p.init == nil {
		return nil
	}
	ctx := luaContextTable(p.state, width, height, 0, 0)
	return p.state.CallByParam(lua.P{Fn: p.init, NRet: 0, Protect: true}, ctx)
}

func (p *luaPlugin) Paint(width, height, frame int, elapsed float64) ([]drawCommand, error) {
	ctx := luaContextTable(p.state, width, height, frame, elapsed)
	if err := p.state.CallByParam(lua.P{Fn: p.paint, NRet: 1, Protect: true}, ctx); err != nil {
		return nil, fmt.Errorf("plugin paint failed: %w", err)
	}
	ret := p.state.Get(-1)
	p.state.Pop(1)
	tbl, ok := ret.(*lua.LTable)
	if !ok {
		return nil, fmt.Errorf("plugin.paint must return an array of draw commands")
	}
	commands := make([]drawCommand, 0, tbl.Len())
	var parseErr error
	tbl.ForEach(func(_, value lua.LValue) {
		if parseErr != nil {
			return
		}
		cmdTable, ok := value.(*lua.LTable)
		if !ok {
			parseErr = fmt.Errorf("draw command must be a table")
			return
		}
		x := int(lua.LVAsNumber(cmdTable.RawGetString("x"))) - 1
		y := int(lua.LVAsNumber(cmdTable.RawGetString("y"))) - 1
		chText := cmdTable.RawGetString("ch").String()
		if chText == "" {
			chText = " "
		}
		r, _ := utf8.DecodeRuneInString(chText)
		if r == utf8.RuneError {
			r = ' '
		}
		color := ""
		colorVal := cmdTable.RawGetString("color")
		if colorVal.Type() != lua.LTNil {
			color = strings.TrimSpace(colorVal.String())
		}
		commands = append(commands, drawCommand{x: x, y: y, ch: r, color: color})
	})
	if parseErr != nil {
		return nil, parseErr
	}
	return commands, nil
}

func terminalSize() (int, int) {
	if w, h, err := term.GetSize(int(os.Stdout.Fd())); err == nil {
		return max(10, w), max(5, h)
	}
	return 80, 24
}

func clampFPS(v int) int {
	if v < 1 {
		return 1
	}
	if v > 120 {
		return 120
	}
	return v
}

func drawStatusLine(buffer *screenBuffer, text string) {
	if buffer.height < 1 {
		return
	}
	y := buffer.height - 1
	for x := 0; x < buffer.width; x++ {
		buffer.Set(x, y, ' ', "30;47")
	}
	for i, r := range text {
		if i >= buffer.width {
			break
		}
		buffer.Set(i, y, r, "30;47")
	}
}

func runAnimation(plugins []*luaPlugin, startIndex, fps int, duration float64) error {
	if len(plugins) == 0 {
		return fmt.Errorf("no plugins loaded")
	}
	if startIndex < 0 || startIndex >= len(plugins) {
		startIndex = 0
	}

	frameDelay := time.Second / time.Duration(clampFPS(fps))
	width, height := terminalSize()
	buffer := newScreenBuffer(width, height)

	current := startIndex
	renderHeight := height
	if err := plugins[current].Init(width, renderHeight); err != nil {
		return fmt.Errorf("plugin init failed: %w", err)
	}

	var statusText string
	statusUntil := time.Time{}
	showStatus := func() {
		statusText = fmt.Sprintf("%d/%d %s v%s | W/A prev  S/D next  Q quit", current+1, len(plugins), plugins[current].meta.Name, plugins[current].meta.Version)
		statusUntil = time.Now().Add(2 * time.Second)
	}

	if term.IsTerminal(int(os.Stdin.Fd())) {
		oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
		if err == nil {
			defer func() {
				_ = term.Restore(int(os.Stdin.Fd()), oldState)
			}()
		}
	}

	keyCh := make(chan byte, 32)
	go func() {
		buf := make([]byte, 1)
		for {
			n, err := os.Stdin.Read(buf)
			if err != nil || n == 0 {
				return
			}
			select {
			case keyCh <- buf[0]:
			default:
			}
		}
	}()

	fmt.Print("\x1b[2J\x1b[?25l")
	defer fmt.Print("\x1b[0m\x1b[?25h\n")
	start := time.Now()
	pluginStart := start
	frame := 0
	ticker := time.NewTicker(frameDelay)
	defer ticker.Stop()

	for {
		select {
		case key := <-keyCh:
			switched := false
			switch key {
			case 'a', 'A', 'w', 'W':
				current = (current - 1 + len(plugins)) % len(plugins)
				switched = true
			case 'd', 'D', 's', 'S':
				current = (current + 1) % len(plugins)
				switched = true
			case 'q', 'Q', 3:
				return nil
			}
			if switched {
				renderHeight = max(1, buffer.height-1)
				if err := plugins[current].Init(buffer.width, renderHeight); err != nil {
					return fmt.Errorf("plugin init failed: %w", err)
				}
				pluginStart = time.Now()
				frame = 0
				showStatus()
			}
		default:
		}

		select {
		case <-ticker.C:
		}
		if duration > 0 && time.Since(start).Seconds() >= duration {
			return nil
		}
		newW, newH := terminalSize()
		if newW != buffer.width || newH != buffer.height {
			buffer.Resize(newW, newH)
		}
		buffer.Clear()
		statusVisible := !statusUntil.IsZero() && time.Now().Before(statusUntil)
		renderHeight = buffer.height
		if statusVisible {
			renderHeight = max(1, buffer.height-1)
		}
		elapsed := time.Since(pluginStart).Seconds()
		commands, err := plugins[current].Paint(buffer.width, renderHeight, frame, elapsed)
		if err != nil {
			return err
		}
		buffer.Apply(commands)
		if statusVisible {
			drawStatusLine(buffer, statusText)
		}
		fmt.Print("\x1b[H")
		fmt.Print(buffer.String())
		frame++
	}
}
