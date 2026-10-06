# Development status

Updated: 2026-10-06

## Implemented

- Cross-platform MusicProject core.
- Versioned .yms codec and portable project storage.
- Project notes and tags (core).
- Shared note editing and undo/redo.
- Composition revision graph (core).
- AI composition context for iterative work after manual edits.
- Musical metrics and AI recommendations (core).
- Explicit AI change plans (core).
- Persistent automation lanes for velocity, pitch and timing.
- Android Compose prototype with Piano Roll and Curve Lab.
- Platform-neutral sync revision model.

### macOS UI (2026-10-06)

- Duplicate note: single history mutation.
- Quantize 1/16 (selected or all).
- Transpose ±1, Humanize (timing/velocity jitter).
- Keyboard: Space, Cmd+Z / Cmd+Shift+Z, Delete, Cmd+D.
- Workspace modes: Compose / Edit / AI (segmented).
- **Transform** — non-destructive AI transform of current pattern via prompt.
- Curve lab types restored (`CurveMode`, `CurveSet`, `CurveEditorView`).
- Note count in toolbar; clear history on open project/MIDI.

## Explicitly not done yet

- Audio playback / render engine (transport is UI flag only).
- Command palette (Cmd+K).
- Multi-select / box selection on Piano Roll.
- Browser / arrangement timeline panel.
- Independent candidate compare UI.

## Next implementation priorities

1. Command palette + centralized shortcuts.
2. Multi-note selection on Piano Roll.
3. Project notes/tags UI in macOS inspector.
4. Candidate A/B compare before Accept AI result.
5. Audio engine foundation (playhead + MIDI preview).
6. Connect Android Piano Roll to MusicProject.
