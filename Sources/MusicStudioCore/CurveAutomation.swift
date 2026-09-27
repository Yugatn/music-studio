import Foundation

public struct CurvePoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x=x; self.y=y }
}

public struct AutomationCurve: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var points: [CurvePoint]

    public init(id: UUID = UUID(), name: String, points: [CurvePoint]) {
        self.id=id; self.name=name; self.points=points
    }

    public func value(at x: Double) -> Double {
        guard let a=points.first, let b=points.last else { return 0.5 }
        if x <= a.x { return a.y }
        if x >= b.x { return b.y }
        for i in 1..<points.count where x <= points[i].x {
            let p=points[i-1], q=points[i]
            let t=(x-p.x)/max(0.0001,q.x-p.x)
            return p.y+(q.y-p.y)*t
        }
        return 0.5
    }
}

public enum CurveOperation: String, Codable, CaseIterable, Sendable {
    case velocity, pitch, timing
    public var title: String { rawValue.capitalized }

    public func apply(to note: inout NoteEvent, value: Double, patternLength: Double) {
        switch self {
        case .velocity: note.velocity=max(1,min(127,Int((value*126+1).rounded())))
        case .pitch: note.pitch=max(24,min(108,note.pitch+Int(((value-0.5)*12).rounded())))
        case .timing: note.startBeat=max(0,min(patternLength-note.durationBeats,note.startBeat+(value-0.5)*0.5))
        }
    }
}
