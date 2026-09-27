# Music Studio project contract

The project contract is intentionally independent of a UI framework.

A project contains:

- project name;
- tempo;
- key;
- scale;
- tracks;
- patterns;
- MIDI notes;
- note pitch;
- note start position in beats;
- note duration;
- velocity;
- MIDI channel.

Automation uses normalized points:

- `x`: normalized time;
- `y`: normalized value.

The same semantic model is used by macOS, iPadOS, iOS and Android clients.

Future format versions must be backward-compatible where practical and include an explicit schema version before introducing incompatible changes.
