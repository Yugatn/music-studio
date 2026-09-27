import Foundation

public struct ProjectHistory: Sendable {
    private var undoStack: [MusicProject] = []
    private var redoStack: [MusicProject] = []

    public init() {}

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func record(_ project: MusicProject) {
        undoStack.append(project)
        redoStack.removeAll()
    }

    public mutating func undo(current: MusicProject) -> MusicProject? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return previous
    }

    public mutating func redo(current: MusicProject) -> MusicProject? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }

    public mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
