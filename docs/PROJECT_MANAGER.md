# Project Manager

Music Studio will use a project-manager workflow inspired by the practical project browser pattern found in professional creative applications.

## Home screen

- Recent Projects
- Favorites
- Local Projects
- Synced Projects
- New Project
- Open Project
- Import MIDI

## New Project

The creation dialog should collect:

- Project name
- Location
- BPM
- Key
- Scale
- Time signature
- Template

Templates may include:

- Empty
- AI Melody
- Beat
- Song
- Ambient
- Custom

## Project lifecycle

Create → Open → Edit → Save → Close → Recent.

Projects remain independent containers. Opening a project must restore its MusicProject, notes, automation, AI revision context and metadata.

## Safety

The project manager must validate a project before loading it into the editor. Untrusted files must not execute code. Saving should be atomic to prevent partial project corruption.

## Planned UI

macOS:
- Project Manager window with large recent-project cards.
- Sidebar for locations and favorites.
- Search and sorting.
- Context actions: Open, Rename, Duplicate, Reveal, Delete.

iPad:
- Split-view project browser with touch-friendly cards.

Android:
- Compose project browser with the same project semantics.

The visual language should be native to each platform while the project lifecycle and file format remain shared through MusicStudioCore.
