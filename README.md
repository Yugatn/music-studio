# Yugatn Music Studio

AI-first music workstation with a native macOS editor and a cross-platform musical core.

## Current capabilities

- AI-assisted melody generation and iterative transformation.
- Editable Piano Roll.
- MIDI import and export.
- Key/scale-aware demo composition.
- Curve Lab with persistent Velocity, Pitch and Timing automation lanes.
- Versioned `.yms` project format.
- Persistent project notes and tags.
- Undo/Redo for project mutations.
- Composition revision graph for iterative AI work.
- Musical metrics and AI composition recommendations.
- Explicit AI change plans.
- Android Compose prototype.
- Cross-platform project storage and sync model.

## Development model

AI generation does not have to overwrite the musician's work. The intended workflow is:

**Generate → Edit → Analyze → Recommend → Apply/Reject → Revise → Compare → Save**

The project model is designed so the current edited composition remains the source context for subsequent AI work.

## Build

    swift build
    swift test
    swift run MusicStudio

## Repository map

- `Sources/MusicStudioCore` — platform-independent musical model and AI/composition services.
- `Sources/MusicStudio` — current macOS SwiftUI application.
- `android` — Android client prototype.
- `docs` — architecture, AI workflow, roadmap and development status.

See `docs/ARCHITECTURE.md`, `docs/AI_COMPOSITION_WORKFLOW.md`, `docs/DEVELOPMENT_STATUS.md` and `docs/ROADMAP.md`.