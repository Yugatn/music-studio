import Foundation

struct NoteEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var pitch: Int
    var startBeat: Double
    var durationBeats: Double
    var velocity: Int
    var channel: Int

    init(id: UUID = UUID(), pitch: Int, startBeat: Double, durationBeats: Double, velocity: Int = 100, channel: Int = 0) {
        self.id = id
        self.pitch = pitch
        self.startBeat = startBeat
        self.durationBeats = durationBeats
        self.velocity = velocity
        self.channel = channel
    }
}

struct Pattern: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var lengthBeats: Double
    var notes: [NoteEvent]

    init(id: UUID = UUID(), name: String, lengthBeats: Double, notes: [NoteEvent] = []) {
        self.id = id
        self.name = name
        self.lengthBeats = lengthBeats
        self.notes = notes
    }
}

enum TrackKind: String, Codable {
    case instrument
    case drums
    case audio
}

struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: TrackKind
    var pattern: Pattern?
}

struct MusicProject: Codable, Equatable {
    var name: String
    var bpm: Double
    var key: String
    var scale: String
    var tracks: [Track]

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
            tracks: [Track(id: UUID(), name: "AI Melody", kind: .instrument, pattern: Pattern(name: "Melody 01", lengthBeats: 8, notes: notes))]
        )
    }()
}
