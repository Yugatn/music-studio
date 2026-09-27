import Foundation

public struct NoteEvent: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var pitch: Int
    public var startBeat: Double
    public var durationBeats: Double
    public var velocity: Int
    public var channel: Int

    public init(id: UUID = UUID(), pitch: Int, startBeat: Double, durationBeats: Double, velocity: Int = 96, channel: Int = 0) {
        self.id=id; self.pitch=pitch; self.startBeat=startBeat; self.durationBeats=durationBeats; self.velocity=velocity; self.channel=channel
    }
}

public struct Pattern: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var lengthBeats: Double
    public var notes: [NoteEvent]

    public init(id: UUID = UUID(), name: String, lengthBeats: Double, notes: [NoteEvent] = []) {
        self.id=id; self.name=name; self.lengthBeats=lengthBeats; self.notes=notes
    }
}

public enum TrackKind: String, Codable, Sendable { case instrument, audio, drums }

public struct Track: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: TrackKind
    public var pattern: Pattern?

    public init(id: UUID = UUID(), name: String, kind: TrackKind, pattern: Pattern? = nil) {
        self.id=id; self.name=name; self.kind=kind; self.pattern=pattern
    }
}

public struct MusicProject: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var bpm: Double
    public var key: String
    public var scale: String
    public var tracks: [Track]

    public init(id: UUID = UUID(), name: String, bpm: Double, key: String, scale: String, tracks: [Track]) {
        self.id=id; self.name=name; self.bpm=bpm; self.key=key; self.scale=scale; self.tracks=tracks
    }

    public static let demo = MusicProject(
        name: "Untitled",
        bpm: 120,
        key: "C",
        scale: "Major",
        tracks: [Track(name: "AI Melody", kind: .instrument, pattern: Pattern(name: "Melody", lengthBeats: 8))]
    )
}
