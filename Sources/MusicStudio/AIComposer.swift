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
        let pitches = [60, 62, 64, 67, 69, 67, 64, 62]
        let notes = pitches.enumerated().map { index, pitch in
            NoteEvent(pitch: pitch, startBeat: Double(index), durationBeats: 0.75, velocity: 88 + (index % 3) * 5)
        }
        return Pattern(name: "AI Candidate", lengthBeats: Double(max(request.bars, 1) * 4), notes: notes)
    }
}
