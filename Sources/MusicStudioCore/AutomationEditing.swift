import Foundation

public enum AutomationEditing {
    public static func addPoint(to lane: inout AutomationLane, x: Double, y: Double) {
        lane.points.append(AutomationPoint(x: x, y: y))
        lane.points.sort { $0.x < $1.x }
    }

    public static func movePoint(in lane: inout AutomationLane, index: Int, x: Double, y: Double) {
        guard lane.points.indices.contains(index) else { return }
        lane.points[index] = AutomationPoint(x: x, y: y)
        lane.points.sort { $0.x < $1.x }
    }

    public static func removePoint(from lane: inout AutomationLane, index: Int) {
        guard lane.points.count > 2, lane.points.indices.contains(index) else { return }
        lane.points.remove(at: index)
    }
}
