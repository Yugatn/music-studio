# Development status

Updated: 2026-10-06 (evening)

## Implemented

- Cross-platform MusicProject core, .yms, notes/tags model.
- Undo/redo, revision graph (core), automation lanes.
- Demo AI generate + transform.
- Android prototype.

### macOS UI

- Piano Roll: create/drag, quantize, humanize, transpose, duplicate.
- Workspace modes Compose / Edit / AI.
- **Cmd+K command palette** (`CommandPalette.swift`).
- **AI candidate stage**: Generate/Transform → Accept/Reject (does not overwrite until Accept).
- **Project notes & tags** UI in inspector (uses `ProjectMetadataEditing`).
- Curve lab restored.

## Not done

- Audio engine / real transport.
- Multi-select box on Piano Roll.
- Arrangement timeline / browser panel.
- Full candidate A/B visual compare on roll.

## Next

1. Multi-note selection.
2. Playhead + MIDI preview path.
3. Arrangement strip.
4. Candidate overlay on Piano Roll.
