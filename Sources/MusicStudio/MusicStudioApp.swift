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

            CommandMenu("Workspace") {
                Button("Compose Mode") {
                    NotificationCenter.default.post(name: StudioShortcut.setModeCompose, object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Edit Mode") {
                    NotificationCenter.default.post(name: StudioShortcut.setModeEdit, object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("AI Mode") {
                    NotificationCenter.default.post(name: StudioShortcut.setModeAI, object: nil)
                }
                .keyboardShortcut("3", modifiers: [.command])

                Divider()

                Button("Toggle Browser") {
                    NotificationCenter.default.post(name: StudioShortcut.toggleBrowser, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command])

                Button("Toggle Inspector") {
                    NotificationCenter.default.post(name: StudioShortcut.toggleInspector, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])

                Button("Toggle Curve Lab") {
                    NotificationCenter.default.post(name: StudioShortcut.toggleCurves, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command])

                Divider()

                Button("Command Palette…") {
                    NotificationCenter.default.post(name: StudioShortcut.commandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
            }

            CommandMenu("Edit Notes") {
                Button("Quantize 1/16") {
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
            }

            CommandMenu("AI") {
                Button("Generate Melody") {
                    NotificationCenter.default.post(name: StudioShortcut.generate, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button("Transform Pattern") {
                    NotificationCenter.default.post(name: StudioShortcut.transform, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Divider()

                Button("Accept Candidate") {
                    NotificationCenter.default.post(name: StudioShortcut.acceptCandidate, object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Reject Candidate") {
                    NotificationCenter.default.post(name: StudioShortcut.rejectCandidate, object: nil)
                }
                .keyboardShortcut(.escape, modifiers: [.command])
            }
        }
    }
}
