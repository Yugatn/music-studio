import SwiftUI
import UniformTypeIdentifiers

@main
struct MusicStudioApp: App {
    @State private var project = MusicProject.demo

    var body: some Scene {
        WindowGroup {
            ContentView(project: $project)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open MIDI…") {
                    NotificationCenter.default.post(name: .openMIDIFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Open Project…") {
                    NotificationCenter.default.post(name: .openProjectFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Save Project…") {
                    NotificationCenter.default.post(name: .saveProjectFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let openMIDIFile = Notification.Name("MusicStudio.openMIDIFile")
    static let openProjectFile = Notification.Name("MusicStudio.openProjectFile")
    static let saveProjectFile = Notification.Name("MusicStudio.saveProjectFile")
}
