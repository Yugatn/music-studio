# Yugatn Music Studio

AI-first music workstation (native macOS). Generate melodies with local or **connected remote AI agents**, edit in Piano Roll, then ask the agent to **rework after your edits** without silent overwrite.

## Download / run on Mac

### Option A — Build the `.app` (recommended)

On a Mac with **macOS 14+** and **Xcode / Swift 6**:

```bash
git clone https://github.com/Yugatn/music-studio.git
cd music-studio
chmod +x scripts/build-macos-app.sh
./scripts/build-macos-app.sh
open dist/MusicStudio.app
```

Artifacts:

- `dist/MusicStudio.app` — double-click to run  
- `dist/MusicStudio-macOS.zip` — share / archive  

### Option B — Run from source

```bash
git clone https://github.com/Yugatn/music-studio.git
cd music-studio
swift run MusicStudio
```

> Pre-built binaries are not published from this environment. Build on your Mac with the script above.

## Connect an AI (remote)

1. Open the app → mode **AI** or **Compose**.  
2. Inspector → **Connect AI…**  
3. Enable remote AI and set:

| Field | Example |
|-------|---------|
| Base URL | `https://api.openai.com/v1` |
| API key | your key |
| Model | `gpt-4o-mini` |
| Compose path | `/chat/completions` |

4. **Save & connect** — agent **Remote AI** appears in the picker.  
5. **Generate** / **Rework after edits** use the remote model when possible; on failure the local engine is used.

Keys are stored only under Application Support (`~/Library/Application Support/MusicStudio/ai-connection.json`), not in project files.

Compatible with **OpenAI Chat Completions** and similar APIs that return JSON notes. Remote responses are validated and normalized before they become candidates; malformed or oversized responses are rejected and the local composer is used as a fallback.

## Collaborative loop

```
Generate → Accept → you edit notes → Rework after edits → Accept / Reject
```

See `docs/AI_AGENT_LOOP.md`.

## Features (current)

- Local + remote AI agents, candidate overlay, explicit Accept/Reject  
- Piano Roll, multi-select, quantize, humanize  
- MIDI import/export, `.yms` projects  
- Workspace modes, Cmd+K, keyboard shortcuts
- Rework from the current human-edited pattern without silent overwrite  

## Docs

- `docs/AI_AGENT_LOOP.md` — agent protocol  
- `docs/UX_PRINCIPLES.md` — shortcuts and panels  
- `docs/ROADMAP.md` — longer-term plan  
