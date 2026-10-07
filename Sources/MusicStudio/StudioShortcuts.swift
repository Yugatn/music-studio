import SwiftUI

/// App-wide shortcut notifications. ContentView listens; menus post via `.commands`.
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

/// Previously hosted invisible `Button`s with `.keyboardShortcut` inside the window
/// hierarchy. On macOS those controls can still intercept mouse hits despite
/// `frame(0)` / `opacity(0)` / `allowsHitTesting(false)`, so clicks appeared to
/// press UI without running the intended chrome/inspector actions.
/// Shortcuts remain registered only via `MusicStudioApp.commands`.
struct StudioShortcutBridge: View {
    var body: some View {
        EmptyView()
    }
}
