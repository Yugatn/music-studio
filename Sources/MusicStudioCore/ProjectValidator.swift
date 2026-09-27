import Foundation

public struct ProjectValidationLimits: Sendable {
    public var maxTracks: Int
    public var maxNotesPerPattern: Int
    public var maxAutomationPointsPerLane: Int
    public var minBPM: Double
    public var maxBPM: Double

    public init(maxTracks: Int = 256, maxNotesPerPattern: Int = 200_000, maxAutomationPointsPerLane: Int = 50_000, minBPM: Double = 20, maxBPM: Double = 300) {
        self.maxTracks=maxTracks; self.maxNotesPerPattern=maxNotesPerPattern
        self.maxAutomationPointsPerLane=maxAutomationPointsPerLane
        self.minBPM=minBPM; self.maxBPM=maxBPM
    }
}

public enum ProjectValidationError: Error, Equatable {
    case tooManyTracks
    case tooManyNotes
    case tooManyAutomationPoints
    case invalidBPM
    case invalidPitch
    case invalidVelocity
    case invalidDuration
    case invalidAutomationValue
}

public enum ProjectValidator {
    public static func validate(_ project: MusicProject, limits: ProjectValidationLimits = .init()) throws {
        guard project.tracks.count <= limits.maxTracks else { throw ProjectValidationError.tooManyTracks }
        guard project.bpm.isFinite, project.bpm >= limits.minBPM, project.bpm <= limits.maxBPM else { throw ProjectValidationError.invalidBPM }

        for track in project.tracks {
            if let pattern = track.pattern {
                guard pattern.notes.count <= limits.maxNotesPerPattern else { throw ProjectValidationError.tooManyNotes }
                for note in pattern.notes {
                    guard (0...127).contains(note.pitch) else { throw ProjectValidationError.invalidPitch }
                    guard (1...127).contains(note.velocity) else { throw ProjectValidationError.invalidVelocity }
                    guard note.durationBeats.isFinite, note.durationBeats > 0 else { throw ProjectValidationError.invalidDuration }
                }
            }
            for lane in track.automation {
                guard lane.points.count <= limits.maxAutomationPointsPerLane else { throw ProjectValidationError.tooManyAutomationPoints }
                for point in lane.points {
                    guard point.x.isFinite, point.y.isFinite, (0...1).contains(point.x), (0...1).contains(point.y) else {
                        throw ProjectValidationError.invalidAutomationValue
                    }
                }
            }
        }
    }
}
