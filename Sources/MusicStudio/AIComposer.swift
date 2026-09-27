import Foundation

struct MelodyRequest {
    var prompt: String
    var bpm: Double
    var key: String
    var scale: String
    var bars: Int
}

protocol AIComposerProvider {
    func generateMelody(_ request: MelodyRequest) async throws -> Pattern
}

struct DemoAIComposer: AIComposerProvider {
    func generateMelody(_ request: MelodyRequest) async throws -> Pattern {
        let root = rootPitchClass(for: request.key)
        let scale = scaleIntervals(for: request.scale)
        let degrees = [0, 1, 2, 4, 5, 4, 2, 1]
        let lengthBeats = Double(max(1, request.bars) * 4)

        let notes = degrees.enumerated().map { index, degree in
            let octave = degree >= scale.count ? 1 : 0
            let interval = scale[degree % scale.count]
            let pitch = 60 + root + interval + octave * 12
            return NoteEvent(
                pitch: min(108, max(24, pitch)),
                startBeat: Double(index) * 0.5,
                durationBeats: 0.5,
                velocity: 88 + (index % 3) * 5
            )
        }

        return Pattern(name: "AI Candidate", lengthBeats: lengthBeats, notes: notes)
    }

    private func rootPitchClass(for key: String) -> Int {
        switch key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "c": return 0
        case "c♯", "c#": return 1
        case "d♭", "db": return 1
        case "d": return 2
        case "d♯", "d#": return 3
        case "e♭", "eb": return 3
        case "e": return 4
        case "f": return 5
        case "f♯", "f#": return 6
        case "g♭", "gb": return 6
        case "g": return 7
        case "g♯", "g#": return 8
        case "a♭", "ab": return 8
        case "a": return 9
        case "a♯", "a#": return 10
        case "b♭", "bb": return 10
        case "b": return 11
        default: return 0
        }
    }

    private func scaleIntervals(for scale: String) -> [Int] {
        switch scale.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "minor", "natural minor", "aeolian":
            return [0, 2, 3, 5, 7, 8, 10]
        case "pentatonic", "major pentatonic":
            return [0, 2, 4, 7, 9]
        case "minor pentatonic":
            return [0, 3, 5, 7, 10]
        default:
            return [0, 2, 4, 5, 7, 9, 11]
        }
    }
}
