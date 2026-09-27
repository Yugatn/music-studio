# Music Studio Android

Android is a first-class target, not a web wrapper.

## Planned stack

- Kotlin
- Jetpack Compose
- Android MIDI APIs where available
- the platform-neutral MusicProject serialization contract
- offline-first local project storage
- shared sync protocol with macOS, iOS and iPadOS

## Initial Android scope

1. Open/save Music Studio projects.
2. Piano Roll touch editing.
3. Curve Lab.
4. AI composition requests.
5. MIDI import/export where supported.
6. Device sync.

The Android application must not copy Swift implementation details. It consumes the same portable project data and synchronization protocol.

## Repository layout

The Android client will live under:

`android/`

while the Apple clients use Swift/SwiftUI and the shared Apple musical core remains under:

`Sources/MusicStudioCore/`.
