import Foundation
import MusicStudioCore

struct MelodyRequest {
    var prompt: String
    var bpm: Double
    var key: String
    var scale: String
    var bars: Int
}

protocol AIComposerProvider {
    func generateMelody(_ request: MelodyRequest) async throws -> Pattern
    func transform(_ pattern: Pattern, request: MelodyRequest, instruction: String) async throws -> Pattern
    func reworkAfterSubject(
        _ pattern: Pattern,
        request: MelodyRequest,
        instruction: String,
        aggressive: Bool
    ) async throws -> Pattern
}

extension AIComposerProvider {
    func reworkAfterSubject(
        _ pattern: Pattern,
        request: MelodyRequest,
        instruction: String,
        aggressive: Bool = false
    ) async throws -> Pattern {
        try await transform(pattern, request: request, instruction: instruction)
    }
}

struct DemoAIComposer: AIComposerProvider {
    func generateMelody(_ request: MelodyRequest) async throws -> Pattern {
        makePattern(request: request)
    }

    func transform(_ pattern: Pattern, request: MelodyRequest, instruction: String) async throws -> Pattern {
        try await reworkAfterSubject(pattern, request: request, instruction: instruction, aggressive: false)
    }

    /// Rework after the subject edited the melody: never discard note skeleton silently.
    func reworkAfterSubject(
        _ pattern: Pattern,
        request: MelodyRequest,
        instruction: String,
        aggressive: Bool = false
    ) async throws -> Pattern {
        var result = pattern
        let text = instruction.lowercased()
        let root = rootPitchClass(for: request.key)
        let scale = scaleIntervals(for: request.scale)

        // 1) Instructional transforms on existing notes (subject material is base)
        if text.contains("faster") || text.contains("быстр") {
            result.notes = result.notes.map { note in
                var n = note
                n.startBeat *= aggressive ? 0.65 : 0.8
                n.durationBeats = max(0.25, n.durationBeats * (aggressive ? 0.7 : 0.85))
                return n
            }
        }
        if text.contains("slower") || text.contains("медлен") {
            result.notes = result.notes.map { note in
                var n = note
                n.startBeat *= 1.15
                n.durationBeats = min(4, n.durationBeats * 1.2)
                return n
            }
        }
        if text.contains("higher") || text.contains("выше") {
            let delta = aggressive ? 4 : 2
            result.notes = result.notes.map { note in
                var n = note
                n.pitch = min(108, n.pitch + delta)
                return n
            }
        }
        if text.contains("lower") || text.contains("ниже") {
            let delta = aggressive ? 4 : 2
            result.notes = result.notes.map { note in
                var n = note
                n.pitch = max(24, n.pitch - delta)
                return n
            }
        }
        if text.contains("soft") || text.contains("тиш") || text.contains("quiet") {
            result.notes = result.notes.map { note in
                var n = note
                n.velocity = max(1, n.velocity - (aggressive ? 24 : 12))
                return n
            }
        }
        if text.contains("loud") || text.contains("гром") || text.contains("energy") {
            result.notes = result.notes.map { note in
                var n = note
                n.velocity = min(127, n.velocity + (aggressive ? 20 : 10))
                return n
            }
        }

        // 2) Quantize to key/scale (preserve timing from subject)
        result.notes = result.notes.map { note in
            var n = note
            n.pitch = snapToScale(n.pitch, root: root, scale: scale)
            return n
        }

        // 3) Optional density variation without wiping subject skeleton
        if text.contains("variation") || text.contains("вариац") || text.contains("denser") || aggressive {
            var extra: [NoteEvent] = []
            for (index, note) in result.notes.enumerated() where index % 2 == 0 {
                let degree = scale[index % scale.count]
                let pitch = snapToScale(note.pitch + degree, root: root, scale: scale)
                let start = note.startBeat + note.durationBeats * 0.5
                if start + 0.25 <= result.lengthBeats {
                    extra.append(NoteEvent(
                        pitch: pitch,
                        startBeat: start,
                        durationBeats: max(0.25, note.durationBeats * 0.5),
                        velocity: max(1, note.velocity - 8)
                    ))
                }
            }
            result.notes.append(contentsOf: extra)
            result.notes.sort { $0.startBeat < $1.startBeat }
        }

        // 4) Mild humanize if requested
        if text.contains("human") || text.contains("живин") {
            result.notes = result.notes.map { note in
                var n = note
                n.startBeat = max(0, n.startBeat + Double.random(in: -0.03...0.03))
                n.velocity = max(1, min(127, n.velocity + Int.random(in: -6...6)))
                return n
            }
        }

        // Default light contour polish when no keyword matched hard transforms
        if result.notes == pattern.notes {
            result.notes = result.notes.enumerated().map { index, note in
                var n = note
                n.velocity = max(1, min(127, n.velocity + (index.isMultiple(of: 2) ? 5 : -3)))
                n.pitch = snapToScale(n.pitch, root: root, scale: scale)
                return n
            }
        }

        result.lengthBeats = max(
            result.lengthBeats,
            result.notes.map { $0.startBeat + $0.durationBeats }.max() ?? result.lengthBeats
        )
        result.name = aggressive ? "AI Variation (after subject)" : "AI Rework (after subject)"
        return result
    }

    private func makePattern(request: MelodyRequest) -> Pattern {
        let root = rootPitchClass(for: request.key)
        let scale = scaleIntervals(for: request.scale)
        let degrees = [0, 1, 2, 4, 5, 4, 2, 1]
        let lengthBeats = Double(max(1, request.bars) * 4)
        let notes = degrees.enumerated().map { index, degree in
            let interval = scale[degree % scale.count]
            let octave = degree >= scale.count ? 1 : 0
            return NoteEvent(
                pitch: max(24, min(108, 60 + root + interval + octave * 12)),
                startBeat: Double(index) * 0.5,
                durationBeats: 0.5,
                velocity: 88 + (index % 3) * 5
            )
        }
        return Pattern(name: "AI Candidate", lengthBeats: lengthBeats, notes: notes)
    }

    private func snapToScale(_ pitch: Int, root: Int, scale: [Int]) -> Int {
        let pc = ((pitch % 12) + 12) % 12
        let relative = (pc - root + 12) % 12
        if scale.contains(relative) { return pitch }
        let nearest = scale.min(by: { abs($0 - relative) < abs($1 - relative) }) ?? 0
        let delta = nearest - relative
        return max(24, min(108, pitch + delta))
    }

    private func rootPitchClass(for key: String) -> Int {
        switch key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "c": return 0
        case "c♯", "c#", "d♭", "db": return 1
        case "d": return 2
        case "d♯", "d#", "e♭", "eb": return 3
        case "e": return 4
        case "f": return 5
        case "f♯", "f#", "g♭", "gb": return 6
        case "g": return 7
        case "g♯", "g#", "a♭", "ab": return 8
        case "a": return 9
        case "a♯", "a#", "b♭", "bb": return 10
        case "b": return 11
        default: return 0
        }
    }

    private func scaleIntervals(for scale: String) -> [Int] {
        switch scale.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "minor", "natural minor", "aeolian": return [0, 2, 3, 5, 7, 8, 10]
        case "pentatonic", "major pentatonic": return [0, 2, 4, 7, 9]
        case "minor pentatonic": return [0, 3, 5, 7, 10]
        default: return [0, 2, 4, 5, 7, 9, 11]
        }
    }
}
