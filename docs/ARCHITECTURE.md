# Architecture

## Product model

Yugatn Music Studio is an AI-first digital audio workstation. The central object is a musical project, not an AI-generated audio file.

~~~text
User intent -> AI Composer -> Musical events -> Pattern / Track -> Piano Roll / Arrangement -> Audio Engine -> Export
~~~

The AI layer is replaceable. A local model, remote service or deterministic generator can implement the same provider protocol.

## Core layers

### Project
Owns project metadata, tempo, musical key, scale and tracks.

### Composition
Owns note events, patterns, chords, rhythm and transformations.

### UI
SwiftUI views expose the project without making the UI responsible for musical rules.

### Audio
The future audio engine will be isolated behind an engine boundary.

### MIDI
MIDI parsing and writing are isolated from the composition model. MIDI is an interchange format, not the canonical project representation.

### AI
AI providers return structured composition operations where possible. Audio-generation providers can return rendered audio as a separate asset.

## Canonical note event

A note contains a stable identifier, MIDI pitch, start position in beats, duration in beats, velocity and MIDI channel.

This lets the Piano Roll move, resize, delete and create notes without regenerating the composition.

## Non-destructive AI variation

AI variation operates on a selected region and produces a candidate pattern. The original remains available until the user accepts the change.

~~~text
Selection -> VariationRequest -> Candidate -> Preview -> Accept / Reject
~~~

## Future project format

The planned project format is a package containing structured JSON plus referenced audio assets.
