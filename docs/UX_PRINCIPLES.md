# UX Principles — Music Studio

## Product goal

Comfortable daily control of the program once features exist.
Every new capability must shorten the path from idea to result, not only add surface area.

## Complexity on demand

- Default surface: **Compose / Edit / AI / Mix** modes.
- Advanced tools (curves, automation, browser, mix strip) appear when needed.
- Panels are **collapsible**; layout state should remain stable across mode switches.
- Never force multi-window workflows for core tasks.

## One-window workflow

Preferred layout:

1. **Top chrome** — transport, project identity, tempo/key, save status, Cmd+K.
2. **Optional left browser** — projects, MIDI, palettes (collapsible).
3. **Center** — arrangement overview strip + Piano Roll.
4. **Optional right inspector** — selection, AI candidate, notes/tags.
5. **Optional bottom** — Curve Lab / future mixer (collapsible).

## Non-destructive AI

- Generate / Transform **stages** a candidate.
- User **Accept** or **Reject** explicitly.
- Ghost overlay on the roll is preview only.
- Undo/redo remains available after Accept.

## Keyboard-first

| Shortcut | Action |
|----------|--------|
| Space | Play / stop (transport flag until audio engine) |
| Cmd+K | Command palette |
| Cmd+Z / Cmd+Shift+Z | Undo / redo |
| Cmd+S | Save project |
| Cmd+O | Open project |
| Cmd+D | Duplicate selection |
| Delete | Delete selection |
| Cmd-click | Multi-select notes |

## Management after implementation

When the app is “feature complete enough” to use daily:

- Status of AI work and selection is always visible in chrome or inspector.
- Dangerous actions (overwrite pattern, clear project) require confirmation or undo.
- Autosave and recovery are planned (not yet fully implemented).
- Export is one clear action path (MIDI now; Export Center later).

## Sources of synthesis (principles only)

- Logic: song-focused single window, inspector depth.
- Ableton: session/clip ideas, clear transport.
- FL Studio: piano-roll centrality.
- Bitwig: modulation-ready automation thinking.
- REAPER: keyboard density, non-blocking UI.
- GarageBand: approachable defaults.

We do not copy product UI chrome or trademarks.
