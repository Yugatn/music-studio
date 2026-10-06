# UX Principles — Music Studio

## Product goal

Comfortable daily control of the program once features exist.
Every new capability must shorten the path from idea to result, not only add surface area.

## Complexity on demand

- Default surface: **Compose / Edit / AI** modes.
- Advanced tools (curves, browser) appear when needed.
- Panels are **collapsible**; layout state remains stable across mode switches.

## Keyboard map (all modes)

### Workspace modes

| Shortcut | Action |
|----------|--------|
| **Cmd+1** | Compose mode |
| **Cmd+2** | Edit mode |
| **Cmd+3** | AI mode |

### Panels

| Shortcut | Action |
|----------|--------|
| **Cmd+B** | Toggle Browser |
| **Cmd+I** | Toggle Inspector |
| **Cmd+U** | Toggle Curve Lab |
| **Cmd+K** | Command palette |

### Transport & file

| Shortcut | Action |
|----------|--------|
| **Space** | Play / stop (flag until audio engine) |
| **Cmd+S** | Save project |
| **Cmd+O** | Open project |
| **Cmd+Shift+O** | Open MIDI |

### Notes

| Shortcut | Action |
|----------|--------|
| **Cmd+Z** / **Cmd+Shift+Z** | Undo / redo |
| **Cmd+A** | Select all notes |
| **Cmd+D** | Duplicate selection |
| **Delete** | Delete selection |
| **Cmd+Shift+Q** | Quantize 1/16 |
| **Cmd+Shift+H** | Humanize |
| **Cmd-click** | Multi-select notes |

### AI

| Shortcut | Action |
|----------|--------|
| **Cmd+Shift+G** | Generate melody |
| **Cmd+Shift+T** | Transform pattern |
| **Cmd+Return** | Accept candidate |
| **Cmd+Escape** | Reject candidate |

Menus: **Workspace**, **Edit Notes**, **AI** mirror these shortcuts.

## Non-destructive AI

Generate / Transform stages a candidate → Accept or Reject explicitly.

## Sources of synthesis (principles only)

Logic, Ableton, FL Studio, Bitwig, REAPER, GarageBand — principles only, no UI copying.
