import SwiftUI

struct StudioCommand: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let keywords: [String]
    let action: () -> Void

    init(id: String, title: String, subtitle: String? = nil, keywords: [String] = [], action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.keywords = keywords
        self.action = action
    }
}

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    let commands: [StudioCommand]
    @State private var query = ""
    @State private var highlight = 0

    private var filtered: [StudioCommand] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return commands }
        return commands.filter { cmd in
            if cmd.title.lowercased().contains(q) { return true }
            if let s = cmd.subtitle, s.lowercased().contains(q) { return true }
            return cmd.keywords.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type a command…", text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit { runHighlighted() }
                Button("Esc") { isPresented = false }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(12)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, cmd in
                        Button {
                            cmd.action()
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cmd.title)
                                    if let subtitle = cmd.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(index == highlight ? Color.accentColor.opacity(0.15) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 20)
        .onChange(of: query) { _, _ in highlight = 0 }
        .onAppear { query = ""; highlight = 0 }
    }

    private func runHighlighted() {
        let list = filtered
        guard list.indices.contains(highlight) else { return }
        list[highlight].action()
        isPresented = false
    }
}
