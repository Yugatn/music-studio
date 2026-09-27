import Foundation
import MusicStudioCore

typealias NoteEvent = MusicStudioCore.NoteEvent
typealias Pattern = MusicStudioCore.Pattern
typealias TrackKind = MusicStudioCore.TrackKind
typealias Track = MusicStudioCore.Track
typealias MusicProject = MusicStudioCore.MusicProject

extension MusicProject {
    static let demo: MusicProject = {
        let notes = [
            NoteEvent(pitch: 60, startBeat: 0, durationBeats: 1),
            NoteEvent(pitch: 64, startBeat: 1, durationBeats: 1),
            NoteEvent(pitch: 67, startBeat: 2, durationBeats: 1),
            NoteEvent(pitch: 72, startBeat: 3, durationBeats: 1),
            NoteEvent(pitch: 67, startBeat: 4, durationBeats: 2, velocity: 86),
            NoteEvent(pitch: 64, startBeat: 6, durationBeats: 1),
            NoteEvent(pitch: 60, startBeat: 7, durationBeats: 1)
        ]
        return MusicProject(
            name: "New Idea",
            bpm: 120,
            key: "C",
            scale: "Major",
            tracks: [Track(name: "AI Melody", kind: .instrument, pattern: Pattern(name: "Melody 01", lengthBeats: 8, notes: notes))]
        )
    }()
}
