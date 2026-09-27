import Foundation

public enum AutomationTarget: String, Codable, CaseIterable, Sendable {
    case velocity
    case pitch
    case timing
}

public struct AutomationPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x=max(0,min(1,x)); self.y=max(0,min(1,y))
    }
}

public struct AutomationLane: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var target: AutomationTarget
    public var points: [AutomationPoint]
    public var enabled: Bool

    public init(id: UUID = UUID(), name: String, target: AutomationTarget, points: [AutomationPoint] = [AutomationPoint(x: 0, y: 0.5), AutomationPoint(x: 1, y: 0.5)], enabled: Bool = true) {
        self.id=id; self.name=name; self.target=target; self.points=points; self.enabled=enabled
    }

    public func value(at x: Double) -> Double {
        let sorted=points.sorted{$0.x<$1.x}
        guard let first=sorted.first, let last=sorted.last else { return 0.5 }
        if x <= first.x { return first.y }
        if x >= last.x { return last.y }
        for i in 1..<sorted.count where x <= sorted[i].x {
            let a=sorted[i-1], b=sorted[i]
            let t=(x-a.x)/max(0.0001,b.x-a.x)
            return a.y+(b.y-a.y)*t
        }
        return 0.5
    }
}
