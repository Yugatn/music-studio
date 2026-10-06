# AI agent loop — generate, subject edit, rework

## Goal

Music Studio is an **AI-assisted composition app** where:

1. Agents can generate music independently.
2. Multiple agents can be **registered / selected** (local demo now; remote later).
3. After the **subject** (human) edits the melody, an agent can **rework from that edited version** — never silently overwrite without Accept.

## Loop

```
Generate (agent) → Accept → Subject edits Piano Roll
    → Rework after edits (agent uses subject snapshot)
    → Accept / Reject candidate
    → optional Continue independently
```

## Core types (`MusicStudioCore/AIAgent.swift`)

| Type | Role |
|------|------|
| `AIMusicAgent` | Pluggable agent protocol |
| `AIAgentRegistry` | Connect / disconnect agents by id |
| `AIAgentSession` | Turns, subject snapshot, pending candidate |
| `SubjectEditSnapshot` | Pattern after human edit |

## Runtime (`MusicStudio/AIAgentRuntime.swift`)

- **Local Melody** — generate + rework from subject notes  
- **Local Variation** — stronger variation of subject material  
- `AIAgentOrchestrator` — session, select agent, generate / rework / continue / accept / reject  

## UI

- Inspector **AI AGENT** panel (Compose / AI modes)  
- Buttons: Generate · **Rework after edits** · Continue independently · Accept / Reject  
- Session turn log  
- Ghost candidate on Piano Roll  

## Rule

Manual Piano Roll changes call `noteSubjectEdit`.  
**Rework after edits** always takes the **current pattern as source**.  
Candidates stay staged until the subject Accepts.

## Next

- HTTP remote agent adapter  
- Partial apply of change plans  
- Audio audition of candidate vs current  
