import Foundation

struct AutomationCurve: Identifiable, Equatable {
    let id: UUID
    var name: String
    var points: [CurvePointData]

    init(id: UUID = UUID(), name: String, points: [CurvePointData]) {
        self.id = id
        self.name = name
        self.points = points
    }

    func value(at x: Double) -> Double {
        guard let first = points.first, let last = points.last else { return 0.5 }
        if x <= first.x { return first.y }
        if x >= last.x { return last.y }
        for index in 1..<points.count where x <= points[index].x {
            let a = points[index - 1]
            let b = points[index]
            let t = (x - a.x) / max(0.0001, b.x - a.x)
            return a.y + (b.y - a.y) * t
        }
        return 0.5
    }
}

struct CurvePointData: Equatable {
    var x: Double
    var y: Double
}

enum CurveOperation {
    case velocity
    case pitch
    case timing

    var title: String {
        switch self {
        case .velocity: return "Velocity"
        case .pitch: return "Pitch"
        case .timing: return "Timing"
        }
    }

    func apply(to note: inout NoteEvent, value: Double, patternLength: Double) {
        switch self {
        case .velocity:
            note.velocity = max(1, min(127, Int((value * 126 + 1).rounded())))
        case .pitch:
            note.pitch = max(24, min(108, note.pitch + Int(((value - 0.5) * 12).rounded())))
        case .timing:
            note.startBeat = max(0, min(patternLength - note.durationBeats, note.startBeat + (value - 0.5) * 0.5))
        }
    }
}
