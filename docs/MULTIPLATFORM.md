# Multiplatform architecture

MusicStudio is being built around one portable musical project model.

## Targets

- macOS: full DAW, audio engine, mixer, plugins and advanced editing.
- iPadOS: touch-first DAW, Apple Pencil Curve Lab, Piano Roll and AI composition.
- iOS: compact composition and editing workspace.
- Android: compact/full mobile client using the same project interchange format and sync protocol.

## Shared contract

The portable contract is the serialized `MusicProject` model from `MusicStudioCore`.

The project format must remain platform-neutral. Android must not depend on Swift types. Mobile clients exchange project data through the documented serialized representation and synchronization protocol.

## Sync model

The local project remains usable offline.

Future sync layers should use:

1. project identifier;
2. monotonically increasing revision;
3. device identifier;
4. operation/change records;
5. conflict detection;
6. deterministic merge;
7. explicit recovery from conflicts.

Real-time collaboration is not required for the first mobile release.

## UI roles

### iPad

Full editor with:
- Piano Roll;
- Curve Lab;
- AI Composer;
- project/track browser;
- touch and Apple Pencil gestures.

### iPhone

Fast editor with:
- Compose;
- Curves;
- AI;
- Project;
- MIDI/project import and export.

### Android

Native Android client with:
- Compose UI;
- Piano Roll;
- Curve Lab;
- AI Composer;
- project import/export;
- later sync with macOS/iOS/iPadOS.

Android is intentionally kept separate from the Swift implementation while sharing the project contract.
