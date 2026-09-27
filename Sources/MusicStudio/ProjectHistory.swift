import Foundation
import Observation

@Observable
final class ProjectHistory {
    private(set) var project: MusicProject
    private var undoStack: [MusicProject] = []
    private var redoStack: [MusicProject] = []

    init(project: MusicProject) {
        self.project = project
    }

    func update(_ mutation: (inout MusicProject) -> Void) {
        let before = project
        mutation(&project)
        guard before != project else { return }
        undoStack.append(before)
        redoStack.removeAll()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(project)
        project = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(project)
        project = next
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}
