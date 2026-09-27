# Open-source research synthesis

This document records architectural lessons from major open-source music applications reviewed during project planning. Concepts are used as engineering references; source code is not copied.

## LMMS

https://github.com/LMMS/lmms

Piano Roll, pattern sequencing, Song Editor arrangement, mixer/instrument separation and MIDI/plugin interoperability inform the core workflow.

## Zrythm

https://github.com/zrythm/zrythm

Clip looping and cloning, adaptive snapping, multiple editing tools, velocity editing, chord tools and plugin-oriented architecture inform the editor and future arrangement engine.

## Hydrogen

https://github.com/hydrogen-music/hydrogen

Pattern-based drum sequencing, MIDI support, detailed note properties and automation inform the future Drum Grid.

## MuseScore

https://github.com/musescore/MuseScore

Symbolic music representation, MIDI import/export and MusicXML interoperability inform the composition model.

## Ardour

https://github.com/Ardour/ardour

Separation of audio, MIDI and routing concerns plus non-destructive timeline editing inform the future audio architecture.

## AI generation

https://github.com/ace-step/ACE-Step

ACE-Step demonstrates open-source generated-audio workflows. Music Studio treats generated audio and generated symbolic composition as separate capabilities because an audio file alone is not enough for editable Piano Roll work.

## Licensing rule

Before incorporating third-party source code, record the project and version, license, exact files, modifications and distribution obligations. The initial implementation uses original code against public APIs and documented concepts.
