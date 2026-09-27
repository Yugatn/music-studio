import Foundation

public enum AutomationApplication {
    public static func apply(_ lane: AutomationLane, to pattern: inout Pattern) {
        guard lane.enabled, !pattern.notes.isEmpty else { return }
        let length = max(0.001, pattern.lengthBeats)
        for index in pattern.notes.indices {
            let position = max(0, min(1, pattern.notes[index].startBeat / length))
            let value = lane.value(at: position)
            switch lane.target {
            case .velocity:
                pattern.notes[index].velocity = max(1, min(127, Int((value * 126 + 1).rounded())))
            case .pitch:
                let offset = Int(((value - 0.5) * 12).rounded())
                pattern.notes[index].pitch = max(0, min(127, pattern.notes[index].pitch + offset))
            case .timing:
                let offset = (value - 0.5) * 0.5
                let duration = pattern.notes[index].durationBeats
                pattern.notes[index].startBeat = max(0, min(length - duration, pattern.notes[index].startBeat + offset))
            }
        }
    }

    public static func preview(_ lane: AutomationLane, pattern: Pattern) -> Pattern {
        var copy = pattern
        apply(lane, to: &copy)
        return copy
    }
}
