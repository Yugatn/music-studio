import SwiftUI

@main
struct MusicStudioApp: App {
    @State private var project = MusicProject.demo

    var body: some Scene {
        WindowGroup {
            ContentView(project: $project)
                .frame(minWidth: 1100, minHeight: 700)
        }
    }
}
