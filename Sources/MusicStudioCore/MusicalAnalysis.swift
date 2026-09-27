import Foundation

public struct MusicalMetrics: Codable, Equatable, Sendable {
    public let noteCount: Int
    public let averageVelocity: Double
    public let rhythmicDensity: Double
    public let registerCenter: Double
    public let pitchRange: Int
    public let durationBeats: Double

    public init(noteCount: Int, averageVelocity: Double, rhythmicDensity: Double, registerCenter: Double, pitchRange: Int, durationBeats: Double) {
        self.noteCount=noteCount; self.averageVelocity=averageVelocity; self.rhythmicDensity=rhythmicDensity; self.registerCenter=registerCenter; self.pitchRange=pitchRange; self.durationBeats=durationBeats
    }
}

public enum MusicalAnalyzer {
    public static func analyze(_ project: MusicProject) -> MusicalMetrics {
        let notes = project.tracks.compactMap { $0.pattern?.notes }.flatMap { $0 }
        guard !notes.isEmpty else { return MusicalMetrics(noteCount: 0, averageVelocity: 0, rhythmicDensity: 0, registerCenter: 0, pitchRange: 0, durationBeats: 0) }
        let velocities = notes.map { Double($0.velocity) }
        let pitches = notes.map { $0.pitch }
        let end = notes.map { $0.startBeat + $0.durationBeats }.max() ?? 0
        let range = (pitches.max() ?? 0) - (pitches.min() ?? 0)
        return MusicalMetrics(
            noteCount: notes.count,
            averageVelocity: velocities.reduce(0,+) / Double(velocities.count),
            rhythmicDensity: end > 0 ? Double(notes.count) / end : 0,
            registerCenter: Double(pitches.reduce(0,+)) / Double(pitches.count),
            pitchRange: range,
            durationBeats: end
        )
    }
}
