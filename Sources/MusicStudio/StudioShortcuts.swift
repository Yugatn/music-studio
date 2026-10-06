import SwiftUI

/// App-wide shortcut notifications. ContentView listens; menus/chrome post.
enum StudioShortcut {
    static let setModeCompose = Notification.Name("MusicStudio.setModeCompose")
    static let setModeEdit = Notification.Name("MusicStudio.setModeEdit")
    static let setModeAI = Notification.Name("MusicStudio.setModeAI")
    static let toggleBrowser = Notification.Name("MusicStudio.toggleBrowser")
    static let toggleInspector = Notification.Name("MusicStudio.toggleInspector")
    static let toggleCurves = Notification.Name("MusicStudio.toggleCurves")
    static let commandPalette = Notification.Name("MusicStudio.commandPalette")
    static let quantize = Notification.Name("MusicStudio.quantize")
    static let humanize = Notification.Name("MusicStudio.humanize")
    static let selectAllNotes = Notification.Name("MusicStudio.selectAllNotes")
    static let acceptCandidate = Notification.Name("MusicStudio.acceptCandidate")
    static let rejectCandidate = Notification.Name("MusicStudio.rejectCandidate")
    static let generate = Notification.Name("MusicStudio.generate")
    static let transform = Notification.Name("MusicStudio.transform")
}

extension Notification.Name {
    static let openMIDIFile = Notification.Name("MusicStudio.openMIDIFile")
    static let openProjectFile = Notification.Name("MusicStudio.openProjectFile")
    static let saveProjectFile = Notification.Name("MusicStudio.saveProjectFile")
}

/// Hidden buttons that install keyboard shortcuts into the responder chain.
/// Place inside the main window content hierarchy.
struct StudioShortcutBridge: View {
    var body: some View {
        Group {
            // Workspace modes — Cmd+1 / Cmd+2 / Cmd+3
            Button("Mode Compose") {
                NotificationCenter.default.post(name: StudioShortcut.setModeCompose, object: nil)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Mode Edit") {
                NotificationCenter.default.post(name: StudioShortcut.setModeEdit, object: nil)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Mode AI") {
                NotificationCenter.default.post(name: StudioShortcut.setModeAI, object: nil)
            }
            .keyboardShortcut("3", modifiers: [.command])

            // Panels — Cmd+B / Cmd+I / Cmd+U (curves)
            Button("Toggle Browser") {
                NotificationCenter.default.post(name: StudioShortcut.toggleBrowser, object: nil)
            }
            .keyboardShortcut("b", modifiers: [.command])

            Button("Toggle Inspector") {
                NotificationCenter.default.post(name: StudioShortcut.toggleInspector, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command])

            Button("Toggle Curves") {
                NotificationCenter.default.post(name: StudioShortcut.toggleCurves, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command])

            // Editing
            Button("Quantize") {
                NotificationCenter.default.post(name: StudioShortcut.quantize, object: nil)
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])

            Button("Humanize") {
                NotificationCenter.default.post(name: StudioShortcut.humanize, object: nil)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Select All Notes") {
                NotificationCenter.default.post(name: StudioShortcut.selectAllNotes, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command])

            // AI
            Button("Generate") {
                NotificationCenter.default.post(name: StudioShortcut.generate, object: nil)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Button("Transform") {
                NotificationCenter.default.post(name: StudioShortcut.transform, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Accept Candidate") {
                NotificationCenter.default.post(name: StudioShortcut.acceptCandidate, object: nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])

            Button("Reject Candidate") {
                NotificationCenter.default.post(name: StudioShortcut.rejectCandidate, object: nil)
            }
            .keyboardShortcut(.escape, modifiers: [.command])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
