# Code map

## Shared core

- `Sources/MusicStudioCore/MusicProject.swift` — project, tracks, patterns and notes.
- `Sources/MusicStudioCore/ProjectEditing.swift` — cross-platform note editing.
- `Sources/MusicStudioCore/ProjectHistory.swift` — undo/redo.
- `Sources/MusicStudioCore/ProjectCodec.swift` — versioned .yms serialization.
- `Sources/MusicStudioCore/ProjectStorage.swift` — portable save/load.
- `Sources/MusicStudioCore/ProjectMetadata.swift` — project notes and tags.
- `Sources/MusicStudioCore/MusicalAnalysis.swift` — musical metrics for AI.
- `Sources/MusicStudioCore/AIComposition.swift` — iterative AI composition context.
- `Sources/MusicStudioCore/AICompositionGuidance.swift` — style, emotion and recommendations.
- `Sources/MusicStudioCore/AIChangePlan.swift` — reviewable AI change plans.
- `Sources/MusicStudioCore/CompositionPreset.swift` — reusable structured musical intents, sound palettes and generation prompt templates.
- `Sources/MusicStudioCore/CompositionHistory.swift` — composition revision graph.
- `Sources/MusicStudioCore/SyncModel.swift` — cross-device revision model.

## macOS

`Sources/MusicStudio/ContentView.swift` contains the current SwiftUI editor, Piano Roll, AI controls, MIDI actions and project file UI.

## Android

`android/app/src/main/java/com/yugatn/musicstudio/MainActivity.kt` contains the current Jetpack Compose mobile prototype with Compose, Piano Roll, Curve Lab and Project screens.

## Documentation

- `docs/MULTIPLATFORM.md`
- `docs/PROJECT_FORMAT.md`
- `docs/AI_COMPOSITION_WORKFLOW.md`
- `docs/SOUND_PALETTE_LIBRARY.md`

The repository is intentionally moving platform-independent behavior into MusicStudioCore so Apple and Android clients can evolve without duplicating musical semantics.
