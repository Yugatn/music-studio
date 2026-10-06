import SwiftUI

/// Compact top chrome: transport, project identity, status.
struct StudioChrome: View {
    @Binding var projectName: String
    @Binding var bpm: Double
    @Binding var isPlaying: Bool
    @Binding var workspaceMode: WorkspaceMode
    var key: String
    var scale: String
    var noteCount: Int
    var selectionCount: Int
    var hasCandidate: Bool
    var isGenerating: Bool
    var canUndo: Bool
    var canRedo: Bool
    var onUndo: () -> Void
    var onRedo: () -> Void
    var onCommandPalette: () -> Void
    var onToggleBrowser: () -> Void
    var onToggleInspector: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Transport cluster
                HStack(spacing: 6) {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 22)
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .help(isPlaying ? "Stop (audio engine not wired yet)" : "Play (transport flag only)")

                    Text(isPlaying ? "PLAY" : "STOP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isPlaying ? Color.accentColor : Color.secondary)
                        .frame(width: 36, alignment: .leading)
                }

                Divider().frame(height: 18)

                Picker("", selection: $workspaceMode) {
                    ForEach(WorkspaceMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                .help("Redistributes panels; does not destroy session state")

                Divider().frame(height: 18)

                TextField("Project", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)

                Stepper("\(Int(bpm)) BPM", value: $bpm, in: 40...240)
                    .frame(width: 120)

                Text("\(key) · \(scale)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 90, alignment: .leading)

                Spacer(minLength: 8)

                statusPills

                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!canUndo)
                .help("Undo")

                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!canRedo)
                .help("Redo")

                Button(action: onToggleBrowser) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle browser")

                Button(action: onToggleInspector) {
                    Image(systemName: "sidebar.right")
                }
                .help("Toggle inspector")

                Button(action: onCommandPalette) {
                    Image(systemName: "command")
                }
                .keyboardShortcut("k", modifiers: [.command])
                .help("Command palette (Cmd+K)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
        }
        .background(.bar)
    }

    private var statusPills: some View {
        HStack(spacing: 6) {
            pill("\(noteCount) notes", tone: .secondary)
            if selectionCount > 0 {
                pill("\(selectionCount) sel", tone: .accent)
            }
            if isGenerating {
                pill("AI…", tone: .orange)
            } else if hasCandidate {
                pill("Candidate", tone: .orange)
            }
        }
    }

    private enum PillTone { case secondary, accent, orange }

    private func pill(_ text: String, tone: PillTone) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background(for: tone), in: Capsule())
            .foregroundStyle(foreground(for: tone))
    }

    private func background(for tone: PillTone) -> Color {
        switch tone {
        case .secondary: return Color.secondary.opacity(0.12)
        case .accent: return Color.accentColor.opacity(0.18)
        case .orange: return Color.orange.opacity(0.2)
        }
    }

    private func foreground(for tone: PillTone) -> Color {
        switch tone {
        case .secondary: return .secondary
        case .accent: return .accentColor
        case .orange: return .orange
        }
    }
}

/// Lightweight arrangement overview for orientation (clip-level later).
struct ArrangementStrip: View {
    let pattern: Pattern
    let candidate: Pattern?
    let bpm: Double
    var barsVisible: Int = 8

    private var lengthBeats: Double {
        max(pattern.lengthBeats, candidate?.lengthBeats ?? 0, Double(barsVisible * 4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ARRANGEMENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f beats · %.1f bars @ %d BPM",
                            lengthBeats,
                            lengthBeats / 4.0,
                            Int(bpm)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.08))

                    // Pattern density bar
                    densityBars(width: geo.size.width, height: geo.size.height, notes: pattern.notes, color: .accentColor.opacity(0.55))

                    // Candidate ghost density
                    if let candidate {
                        densityBars(width: geo.size.width, height: geo.size.height, notes: candidate.notes, color: .orange.opacity(0.35))
                    }

                    // Bar grid
                    ForEach(0...Int(lengthBeats / 4), id: \.self) { bar in
                        let x = CGFloat(Double(bar) * 4 / lengthBeats) * geo.size.width
                        Path { p in
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    }
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(Color.secondary.opacity(0.04))
    }

    private func densityBars(width: CGFloat, height: CGFloat, notes: [NoteEvent], color: Color) -> some View {
        Canvas { context, size in
            guard lengthBeats > 0 else { return }
            for note in notes {
                let x = CGFloat(note.startBeat / lengthBeats) * size.width
                let w = max(2, CGFloat(note.durationBeats / lengthBeats) * size.width)
                let yNorm = CGFloat(108 - note.pitch) / 84.0
                let y = yNorm * (size.height - 6) + 2
                let rect = CGRect(x: x, y: y, width: w, height: 4)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color))
            }
        }
        .frame(width: width, height: height)
    }
}

/// Collapsible left browser placeholder — ready for assets without cluttering compose mode.
struct StudioBrowserPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BROWSER").font(.caption).foregroundStyle(.secondary)
            Group {
                labelRow("Projects", systemImage: "folder")
                labelRow("MIDI", systemImage: "pianokeys")
                labelRow("Palettes", systemImage: "paintpalette")
                labelRow("AI Candidates", systemImage: "sparkles")
                labelRow("Recent", systemImage: "clock")
            }
            Spacer()
            Text("Drag-and-drop landing zone later.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.secondary.opacity(0.05))
    }

    private func labelRow(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}
