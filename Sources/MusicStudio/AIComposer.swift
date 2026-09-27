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
}

struct DemoAIComposer: AIComposerProvider {
    func generateMelody(_ request: MelodyRequest) async throws -> Pattern {
        makePattern(request: request, source: nil, instruction: nil)
    }

    func transform(_ pattern: Pattern, request: MelodyRequest, instruction: String) async throws -> Pattern {
        var result = pattern
        let text = instruction.lowercased()
        if text.contains("faster") || text.contains("быстр") {
            result.notes = pattern.notes.map { note in
                var n = note
                n.startBeat *= 0.75
                n.durationBeats *= 0.75
                return n
            }
            result.lengthBeats = max(1, result.notes.map { $0.startBeat + $0.durationBeats }.max() ?? result.lengthBeats)
        } else if text.contains("higher") || text.contains("выше") {
            result.notes = pattern.notes.map { note in var n=note; n.pitch=min(108,n.pitch+2); return n }
        } else if text.contains("lower") || text.contains("ниже") {
            result.notes = pattern.notes.map { note in var n=note; n.pitch=max(24,n.pitch-2); return n }
        } else {
            result.notes = pattern.notes.enumerated().map { index, note in
                var n=note
                n.velocity=max(1,min(127,n.velocity + (index.isMultiple(of: 2) ? 6 : -4)))
                return n
            }
        }
        result.name = "AI Revision"
        return result
    }

    private func makePattern(request: MelodyRequest, source: Pattern?, instruction: String?) -> Pattern {
        let root = rootPitchClass(for: request.key)
        let scale = scaleIntervals(for: request.scale)
        let degrees = [0,1,2,4,5,4,2,1]
        let lengthBeats = Double(max(1, request.bars) * 4)
        let notes = degrees.enumerated().map { index, degree in
            let interval=scale[degree % scale.count]
            let octave=degree >= scale.count ? 1 : 0
            return NoteEvent(pitch:max(24,min(108,60+root+interval+octave*12)),startBeat:Double(index)*0.5,durationBeats:0.5,velocity:88+(index%3)*5)
        }
        return Pattern(name:"AI Candidate",lengthBeats:lengthBeats,notes:notes)
    }

    private func rootPitchClass(for key: String) -> Int {
        switch key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "c": return 0
        case "c♯","c#","d♭","db": return 1
        case "d": return 2
        case "d♯","d#","e♭","eb": return 3
        case "e": return 4
        case "f": return 5
        case "f♯","f#","g♭","gb": return 6
        case "g": return 7
        case "g♯","g#","a♭","ab": return 8
        case "a": return 9
        case "a♯","a#","b♭","bb": return 10
        case "b": return 11
        default: return 0
        }
    }

    private func scaleIntervals(for scale: String) -> [Int] {
        switch scale.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "minor","natural minor","aeolian": return [0,2,3,5,7,8,10]
        case "pentatonic","major pentatonic": return [0,2,4,7,9]
        case "minor pentatonic": return [0,3,5,7,10]
        default: return [0,2,4,5,7,9,11]
        }
    }
}
