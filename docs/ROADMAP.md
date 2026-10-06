# Roadmap

## Milestone 0 — Foundation

- [x] Repository created
- [x] Native macOS Swift package skeleton
- [x] Core note model
- [x] Piano Roll prototype
- [x] AI provider abstraction
- [x] Test foundation
- [x] Automated CI
- [x] MIDI import/export foundation
- [x] Project save/load foundation

## Milestone 1 — AI Melody Studio

- [x] Prompt composer
- [x] Deterministic local demo melody generation
- [x] Candidate preview / overlay
- [x] Accept/reject candidate
- [x] Editable note creation
- [x] MIDI import
- [x] MIDI export
- [x] Project save/load
- [x] Key/scale-aware demo generation
- [x] Undo/redo foundation
- [x] Velocity editing
- [x] Duration editing
- [x] Quantize
- [x] Humanize
- [x] Rework after human edits
- [x] External AI connection settings
- [x] Remote HTTP AI provider
- [x] Local fallback when remote AI is unavailable
- [x] Remote response validation and note normalization
- [x] Reusable structured composition intent and sound palette presets
- [ ] Connect sound palette selection to the macOS composition UI
- [ ] Pass selected palette intent and prompt to all AI providers

## Milestone 2 — Rhythm

- [ ] Drum Grid
- [ ] Step sequencing
- [ ] Velocity editing
- [ ] Groove templates

## Milestone 3 — Arrangement

- [ ] Playlist
- [ ] Audio clips
- [ ] MIDI clips
- [ ] Looping
- [ ] Takes
- [ ] Markers
- [ ] Waveform view

## Milestone 4 — Audio workstation

- [ ] Audio engine
- [ ] Mixer
- [ ] Buses and sends
- [ ] Metering
- [ ] Offline render
- [ ] WAV/AIFF/FLAC export

## Milestone 5 — AI workstation

- [ ] Harmony generation
- [ ] Bass generation
- [ ] Rhythm generation
- [ ] Arrangement suggestions
- [ ] Audio analysis
- [ ] Local AI provider
- [x] Remote AI provider

## Milestone 6 — Interoperability

- [ ] AudioUnit hosting
- [ ] VST3 hosting
- [ ] CLAP evaluation
- [ ] MusicXML
- [ ] MIDI controller mapping

## Next implementation priority

1. Wire sound palette and composition intent into the visible Compose UI.
2. Add real audio transport with AVAudioEngine instead of the current transport flag.
3. Build the Drum Grid and shared rhythm editing primitives.
4. Add project-level candidate history so rejected and accepted AI variations remain inspectable.
5. Add automated macOS build verification and focused AI protocol tests.
