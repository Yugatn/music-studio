import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum WorkspaceMode: String, CaseIterable, Identifiable {
    case compose, edit, ai
    var id: Self { self }
    var title: String {
        switch self {
        case .compose: return "Compose"
        case .edit: return "Edit"
        case .ai: return "AI"
        }
    }
}

struct ContentView: View {
    @Binding var project: MusicProject
    @State private var isPlaying = false
    @State private var prompt = "melodic electronic intro, evolving but simple"
    @State private var selectedPitch = 60
    @State private var selectedNoteID: UUID?
    @State private var isGenerating = false
    private let composer = DemoAIComposer()
    @State private var history: [MusicProject] = []
    @State private var future: [MusicProject] = []
    @State private var showCurveEditor = false
    @State private var curveMode: CurveMode = .velocity
    @State private var curves = CurveSet.standard
    @State private var workspaceMode: WorkspaceMode = .compose
    @State private var showCommandPalette = false
    @State private var aiCandidate: Pattern?
    @State private var projectNoteDraft = ""
    @State private var tagDraft = ""

    private var noteCount: Int { project.tracks.first?.pattern?.notes.count ?? 0 }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                    .onReceive(NotificationCenter.default.publisher(for: .openMIDIFile)) { _ in openMIDI() }
                    .onReceive(NotificationCenter.default.publisher(for: .openProjectFile)) { _ in openProject() }
                    .onReceive(NotificationCenter.default.publisher(for: .saveProjectFile)) { _ in saveProject() }

                HStack(spacing: 12) {
                    Button { isPlaying.toggle() } label: { Image(systemName: isPlaying ? "pause.fill" : "play.fill") }
                        .keyboardShortcut(.space, modifiers: [])
                        .help("Transport flag only — audio engine not yet wired")

                    Picker("Mode", selection: $workspaceMode) {
                        ForEach(WorkspaceMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)

                    TextField("Project", text: $project.name).frame(width: 140)
                    Stepper("BPM \(Int(project.bpm))", value: $project.bpm, in: 40...240).frame(width: 125)

                    Picker("Key", selection: $project.key) {
                        ForEach(["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"], id: \.self) { Text($0).tag($0) }
                    }.frame(width: 100)

                    Picker("Scale", selection: $project.scale) {
                        ForEach(["Major", "Minor", "Pentatonic", "Minor Pentatonic"], id: \.self) { Text($0).tag($0) }
                    }.frame(width: 130)

                    if workspaceMode != .edit {
                        TextField("Describe a melody or change…", text: $prompt).textFieldStyle(.roundedBorder)
                        Button(isGenerating ? "Working…" : "Generate") { generate() }.disabled(isGenerating)
                        Button("Transform") { transformPattern() }
                            .disabled(isGenerating || noteCount == 0)
                            .help("Stage AI candidate for Accept/Reject")
                    }

                    Button(showCurveEditor ? "Hide Curves" : "Curves") { showCurveEditor.toggle() }
                    Button("Export MIDI") { exportMIDI() }
                    Button { showCommandPalette = true } label: { Image(systemName: "command") }
                        .keyboardShortcut("k", modifiers: [.command])
                        .help("Command palette")
                    Spacer()
                    Text("\(noteCount) notes").font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                .padding(12)

                Divider()

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TRACK").font(.caption).foregroundStyle(.secondary)
                        Text(project.tracks.first?.name ?? "No track").font(.headline)
                        Divider()
                        Text("SELECTED NOTE").font(.caption).foregroundStyle(.secondary)
                        Picker("Pitch", selection: $selectedPitch) {
                            ForEach(36...84, id: \.self) { Text(noteName($0)).tag($0) }
                        }
                        .onChange(of: selectedPitch) { _, newPitch in updateSelectedPitch(newPitch) }

                        if selectedNoteID != nil {
                            HStack {
                                Text("Velocity")
                                Slider(value: selectedVelocityBinding, in: 1...127, step: 1)
                                Text("\(Int(selectedVelocityBinding.wrappedValue))").monospacedDigit()
                            }
                            HStack {
                                Text("Duration")
                                Slider(value: selectedDurationBinding, in: 0.25...4, step: 0.25)
                                Text(String(format: "%.2f", selectedDurationBinding.wrappedValue))
                            }
                        }

                        HStack {
                            Button("Undo") { undo() }.keyboardShortcut("z", modifiers: [.command]).disabled(history.isEmpty)
                            Button("Redo") { redo() }.keyboardShortcut("z", modifiers: [.command, .shift]).disabled(future.isEmpty)
                        }

                        if showCurveEditor || workspaceMode == .edit {
                            Divider()
                            Text("CURVE").font(.caption).foregroundStyle(.secondary)
                            Picker("Parameter", selection: $curveMode) {
                                ForEach(CurveMode.allCases) { Text($0.title).tag($0) }
                            }
                            CurveEditorView(points: curveBinding).frame(height: 160)
                            Button("Apply curve") { applyCurve() }
                        }

                        if selectedNoteID != nil {
                            Button("Delete note", role: .destructive) { deleteSelectedNote() }
                                .keyboardShortcut(.delete, modifiers: [])
                            Button("Duplicate note") { duplicateSelectedNote() }
                                .keyboardShortcut("d", modifiers: [.command])
                            Button("Transpose +1") { transposeSelected(semitones: 1) }
                            Button("Transpose −1") { transposeSelected(semitones: -1) }
                            Button("Deselect") { selectedNoteID = nil }
                        }

                        Button("Quantize 1/16") { quantizeSelectedOrAll(grid: 0.25) }
                        Button("Humanize") { humanizeNotes() }

                        if aiCandidate != nil {
                            Divider()
                            Text("AI CANDIDATE").font(.caption).foregroundStyle(.secondary)
                            Text("\(aiCandidate?.notes.count ?? 0) notes staged")
                                .font(.caption2)
                            HStack {
                                Button("Accept") { acceptCandidate() }
                                Button("Reject", role: .destructive) { aiCandidate = nil }
                            }
                        }

                        Divider()
                        Text("NOTES / TAGS").font(.caption).foregroundStyle(.secondary)
                        TextField("New note", text: $projectNoteDraft)
                        Button("Add note") { addProjectNote() }
                            .disabled(projectNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ForEach(project.metadata.notes.suffix(5)) { note in
                            Text((note.title.isEmpty ? note.text : note.title).prefix(48))
                                .font(.caption2).lineLimit(1)
                        }
                        TextField("Add tag", text: $tagDraft)
                        Button("Add tag") { addTag() }
                            .disabled(tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if !project.metadata.tags.isEmpty {
                            Text(project.metadata.tags.joined(separator: ", "))
                                .font(.caption2).foregroundStyle(.secondary)
                        }

                        Text("Cmd+K command palette. Transport is flag-only until audio engine.")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(16)
                    .frame(width: workspaceMode == .edit ? 260 : 240)

                    Divider()

                    PianoRollView(pattern: patternBinding, selectedPitch: $selectedPitch, selectedNoteID: $selectedNoteID)
                }
            }

            if showCommandPalette {
                Color.black.opacity(0.25).ignoresSafeArea()
                    .onTapGesture { showCommandPalette = false }
                CommandPaletteView(isPresented: $showCommandPalette, commands: studioCommands)
            }
        }
    }

    private var studioCommands: [StudioCommand] {
        [
            StudioCommand(id: "undo", title: "Undo", keywords: ["history"], action: undo),
            StudioCommand(id: "redo", title: "Redo", keywords: ["history"], action: redo),
            StudioCommand(id: "quantize", title: "Quantize 1/16", keywords: ["grid"], action: { quantizeSelectedOrAll(grid: 0.25) }),
            StudioCommand(id: "humanize", title: "Humanize", action: humanizeNotes),
            StudioCommand(id: "generate", title: "Generate AI Melody", keywords: ["ai"], action: generate),
            StudioCommand(id: "transform", title: "Transform Pattern", subtitle: "Stage candidate", keywords: ["ai"], action: transformPattern),
            StudioCommand(id: "accept", title: "Accept AI Candidate", action: acceptCandidate),
            StudioCommand(id: "reject", title: "Reject AI Candidate", action: { aiCandidate = nil }),
            StudioCommand(id: "curves", title: "Toggle Curve Lab", action: { showCurveEditor.toggle() }),
            StudioCommand(id: "export", title: "Export MIDI…", action: exportMIDI),
            StudioCommand(id: "open-midi", title: "Open MIDI…", action: openMIDI),
            StudioCommand(id: "open-project", title: "Open Project…", action: openProject),
            StudioCommand(id: "save", title: "Save Project…", action: saveProject),
            StudioCommand(id: "m-compose", title: "Mode: Compose", action: { workspaceMode = .compose }),
            StudioCommand(id: "m-edit", title: "Mode: Edit", action: { workspaceMode = .edit }),
            StudioCommand(id: "m-ai", title: "Mode: AI", action: { workspaceMode = .ai }),
        ]
    }

    private var curveBinding: Binding<[CurvePoint]> {
        switch curveMode {
        case .velocity: return $curves.velocity
        case .expression: return $curves.expression
        case .pitch: return $curves.pitch
        case .timing: return $curves.timing
        }
    }

    private var currentCurve: [CurvePoint] {
        switch curveMode {
        case .velocity: return curves.velocity
        case .expression: return curves.expression
        case .pitch: return curves.pitch
        case .timing: return curves.timing
        }
    }

    private func applyCurve() {
        mutate { p in
            guard p.tracks.indices.contains(0), var pattern = p.tracks[0].pattern else { return }
            let target: AutomationTarget
            switch curveMode {
            case .velocity: target = .velocity
            case .pitch: target = .pitch
            case .timing: target = .timing
            case .expression: return
            }
            let lane = AutomationLane(name: curveMode.title, target: target, points: currentCurve.map { AutomationPoint(x: $0.x, y: $0.y) })
            if let index = p.tracks[0].automation.firstIndex(where: { $0.target == target }) {
                p.tracks[0].automation[index] = lane
            } else {
                p.tracks[0].automation.append(lane)
            }
            AutomationApplication.apply(lane, to: &pattern)
            p.tracks[0].pattern = pattern
        }
    }

    private func exportMIDI() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.name).mid"
        panel.allowedContentTypes = [.midi]
        guard panel.runModal() == .OK, let url = panel.url, let data = try? MIDIFile.export(project: project) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func openMIDI() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.midi]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url),
           let imported = try? MIDIFileImporter.importProject(data: data, name: url.deletingPathExtension().lastPathComponent) {
            project = imported; selectedNoteID = nil; history.removeAll(); future.removeAll(); aiCandidate = nil
        }
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.musicStudioProject]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let loaded = try? ProjectFile.load(from: url) {
            project = loaded; selectedNoteID = nil; history.removeAll(); future.removeAll(); aiCandidate = nil
        }
    }

    private func saveProject() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.name).yms"
        panel.allowedContentTypes = [.musicStudioProject]
        if panel.runModal() == .OK, let url = panel.url { try? ProjectFile.save(project, to: url) }
    }

    private var patternBinding: Binding<Pattern> {
        Binding(
            get: { project.tracks.first?.pattern ?? Pattern(name: "Empty", lengthBeats: 8) },
            set: { newPattern in
                mutate { p in
                    guard !p.tracks.isEmpty else { return }
                    p.tracks[0].pattern = newPattern
                }
            }
        )
    }

    private func generate() {
        isGenerating = true
        let request = MelodyRequest(prompt: prompt, bpm: project.bpm, key: project.key, scale: project.scale, bars: 2)
        Task {
            if let candidate = try? await composer.generateMelody(request) {
                aiCandidate = candidate
                workspaceMode = .ai
            }
            isGenerating = false
        }
    }

    private func transformPattern() {
        guard let pattern = project.tracks.first?.pattern, !pattern.notes.isEmpty else { return }
        isGenerating = true
        let request = MelodyRequest(prompt: prompt, bpm: project.bpm, key: project.key, scale: project.scale, bars: max(1, Int(pattern.lengthBeats / 4)))
        Task {
            if let revised = try? await composer.transform(pattern, request: request, instruction: prompt) {
                aiCandidate = revised
                workspaceMode = .ai
            }
            isGenerating = false
        }
    }

    private func acceptCandidate() {
        guard let candidate = aiCandidate else { return }
        mutate { p in
            guard !p.tracks.isEmpty else { return }
            p.tracks[0].pattern = candidate
        }
        aiCandidate = nil
        selectedNoteID = nil
    }

    private func addProjectNote() {
        let text = projectNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        mutate { p in ProjectMetadataEditing.addNote(to: &p.metadata, ProjectNote(text: text)) }
        projectNoteDraft = ""
    }

    private func addTag() {
        let tag = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        mutate { p in
            if !p.metadata.tags.contains(tag) {
                p.metadata.tags.append(tag)
                p.metadata.updatedAt = Date()
            }
        }
        tagDraft = ""
    }

    private func mutate(_ change: (inout MusicProject) -> Void) {
        var next = project
        change(&next)
        guard next != project else { return }
        history.append(project); future.removeAll(); project = next
    }

    private func undo() { guard let p = history.popLast() else { return }; future.append(project); project = p }
    private func redo() { guard let p = future.popLast() else { return }; history.append(project); project = p }

    private func updateSelectedPitch(_ pitch: Int) {
        guard let selectedNoteID else { return }
        mutate { p in
            guard var pattern = p.tracks.first?.pattern, let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
            pattern.notes[index].pitch = pitch
            p.tracks[0].pattern = pattern
        }
    }

    private func duplicateSelectedNote() {
        guard let selectedNoteID, let pattern = project.tracks.first?.pattern,
              let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
        let source = pattern.notes[index]
        let copy = NoteEvent(
            pitch: source.pitch,
            startBeat: min(pattern.lengthBeats - source.durationBeats, source.startBeat + 0.5),
            durationBeats: source.durationBeats,
            velocity: source.velocity,
            channel: source.channel
        )
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            pat.notes.append(copy)
            p.tracks[0].pattern = pat
        }
        self.selectedNoteID = copy.id
    }

    private func quantizeSelectedOrAll(grid: Double = 0.25) {
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            for i in pat.notes.indices {
                if let id = selectedNoteID, pat.notes[i].id != id { continue }
                let snapped = (pat.notes[i].startBeat / grid).rounded() * grid
                pat.notes[i].startBeat = max(0, min(pat.lengthBeats - pat.notes[i].durationBeats, snapped))
            }
            p.tracks[0].pattern = pat
        }
    }

    private func humanizeNotes() {
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            for i in pat.notes.indices {
                if let id = selectedNoteID, pat.notes[i].id != id { continue }
                pat.notes[i].startBeat = max(0, min(pat.lengthBeats - pat.notes[i].durationBeats, pat.notes[i].startBeat + Double.random(in: -0.04...0.04)))
                pat.notes[i].velocity = max(1, min(127, pat.notes[i].velocity + Int.random(in: -8...8)))
            }
            p.tracks[0].pattern = pat
        }
    }

    private func transposeSelected(semitones: Int) {
        guard let selectedNoteID else { return }
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern,
                  let index = pat.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
            pat.notes[index].pitch = max(24, min(108, pat.notes[index].pitch + semitones))
            p.tracks[0].pattern = pat
        }
        if let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == selectedNoteID }) {
            selectedPitch = note.pitch
        }
    }

    private func deleteSelectedNote() {
        guard let selectedNoteID else { return }
        mutate { p in
            guard !p.tracks.isEmpty, var pattern = p.tracks[0].pattern else { return }
            pattern.notes.removeAll { $0.id == selectedNoteID }
            p.tracks[0].pattern = pattern
        }
        self.selectedNoteID = nil
    }

    private var selectedVelocityBinding: Binding<Double> {
        Binding(
            get: {
                guard let id = selectedNoteID, let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == id }) else { return 96 }
                return Double(note.velocity)
            },
            set: { updateSelectedVelocity(Int($0.rounded())) }
        )
    }

    private var selectedDurationBinding: Binding<Double> {
        Binding(
            get: {
                guard let id = selectedNoteID, let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == id }) else { return 0.5 }
                return note.durationBeats
            },
            set: { updateSelectedDuration($0) }
        )
    }

    private func updateSelectedVelocity(_ velocity: Int) {
        mutate { p in
            guard let id = selectedNoteID, p.tracks.indices.contains(0), var pattern = p.tracks[0].pattern,
                  let index = pattern.notes.firstIndex(where: { $0.id == id }) else { return }
            pattern.notes[index].velocity = max(1, min(127, velocity))
            p.tracks[0].pattern = pattern
        }
    }

    private func updateSelectedDuration(_ duration: Double) {
        mutate { p in
            guard let id = selectedNoteID, p.tracks.indices.contains(0), var pattern = p.tracks[0].pattern,
                  let index = pattern.notes.firstIndex(where: { $0.id == id }) else { return }
            pattern.notes[index].durationBeats = max(0.25, min(4, duration))
            p.tracks[0].pattern = pattern
        }
    }

    private func noteName(_ pitch: Int) -> String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
        return "\(names[pitch % 12])\(pitch / 12 - 1)"
    }
}

private struct PianoRollView: View {
    @Binding var pattern: Pattern
    @Binding var selectedPitch: Int
    @Binding var selectedNoteID: UUID?
    private let rowHeight: CGFloat = 22
    private let beatWidth: CGFloat = 72
    private let lowestPitch = 36
    private let highestPitch = 84
    private let snap: Double = 0.25

    var body: some View {
        GeometryReader { _ in
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    grid.contentShape(Rectangle())
                        .gesture(SpatialTapGesture(count: 2).onEnded { value in addNote(at: value.location) })
                    ForEach(pattern.notes) { note in
                        NoteCell(note: note, beatWidth: beatWidth, rowHeight: rowHeight, isSelected: selectedNoteID == note.id) { delta in
                            move(noteID: note.id, delta: delta)
                        }
                        .position(
                            x: note.startBeat * beatWidth + note.durationBeats * beatWidth / 2,
                            y: CGFloat(highestPitch - note.pitch) * rowHeight + rowHeight / 2
                        )
                        .onTapGesture { selectedNoteID = note.id; selectedPitch = note.pitch }
                    }
                }
                .frame(width: CGFloat(pattern.lengthBeats) * beatWidth, height: CGFloat(highestPitch - lowestPitch + 1) * rowHeight)
                .padding(30)
            }
        }
    }

    private var grid: some View {
        Canvas { context, size in
            for beat in 0...Int(pattern.lengthBeats) {
                let x = CGFloat(beat) * beatWidth
                var path = Path(); path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.secondary.opacity(beat % 4 == 0 ? 0.55 : 0.22)))
            }
            for row in 0...(highestPitch - lowestPitch) {
                let y = CGFloat(row) * rowHeight
                var path = Path(); path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.secondary.opacity(0.18)))
            }
        }
    }

    private func move(noteID: UUID, delta: CGSize) {
        guard let index = pattern.notes.firstIndex(where: { $0.id == noteID }) else { return }
        var note = pattern.notes[index]
        note.startBeat = max(0, min(pattern.lengthBeats - note.durationBeats, snapBeat(note.startBeat + delta.width / beatWidth)))
        note.pitch = max(lowestPitch, min(highestPitch, Int((Double(note.pitch) - delta.height / rowHeight).rounded())))
        pattern.notes[index] = note
        selectedNoteID = noteID; selectedPitch = note.pitch
    }

    private func addNote(at location: CGPoint) {
        let beat = max(0, min(pattern.lengthBeats - 0.5, snapBeat(location.x / beatWidth)))
        let pitch = max(lowestPitch, min(highestPitch, highestPitch - Int(location.y / rowHeight)))
        let note = NoteEvent(pitch: pitch, startBeat: beat, durationBeats: 0.5, velocity: 96)
        pattern.notes.append(note); selectedNoteID = note.id; selectedPitch = pitch
    }

    private func snapBeat(_ beat: Double) -> Double { (beat / snap).rounded() * snap }
}

private struct NoteCell: View {
    let note: NoteEvent
    let beatWidth: CGFloat
    let rowHeight: CGFloat
    let isSelected: Bool
    let move: (CGSize) -> Void
    @State private var dragStart: CGSize = .zero

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.7))
            .frame(width: max(12, note.durationBeats * beatWidth - 2), height: rowHeight - 3)
            .overlay { Text("\(note.pitch)").font(.system(size: 9, weight: .medium)).foregroundStyle(.white) }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        move(CGSize(width: value.translation.width - dragStart.width, height: value.translation.height - dragStart.height))
                        dragStart = value.translation
                    }
                    .onEnded { _ in dragStart = .zero }
            )
    }
}

enum CurveMode: String, CaseIterable, Identifiable {
    case velocity, expression, pitch, timing
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

private struct CurvePoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
}

private struct CurveSet {
    var velocity: [CurvePoint]
    var expression: [CurvePoint]
    var pitch: [CurvePoint]
    var timing: [CurvePoint]
    static let standard = CurveSet(
        velocity: [CurvePoint(x: 0, y: 0.7), CurvePoint(x: 0.5, y: 0.45), CurvePoint(x: 1, y: 0.8)],
        expression: [CurvePoint(x: 0, y: 0.5), CurvePoint(x: 1, y: 0.5)],
        pitch: [CurvePoint(x: 0, y: 0.5), CurvePoint(x: 1, y: 0.5)],
        timing: [CurvePoint(x: 0, y: 0.5), CurvePoint(x: 1, y: 0.5)]
    )
}

private struct CurveEditorView: View {
    @Binding var points: [CurvePoint]
    var body: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.3))
                Path { p in
                    guard let f = points.first else { return }
                    p.move(to: CGPoint(x: f.x * g.size.width, y: (1 - f.y) * g.size.height))
                    for q in points.dropFirst() {
                        p.addLine(to: CGPoint(x: q.x * g.size.width, y: (1 - q.y) * g.size.height))
                    }
                }.stroke(.accentColor, lineWidth: 2)
                ForEach(points) { q in
                    Circle().fill(.accentColor).frame(width: 10, height: 10)
                        .position(x: q.x * g.size.width, y: (1 - q.y) * g.size.height)
                        .gesture(DragGesture().onChanged { v in
                            if let i = points.firstIndex(where: { $0.id == q.id }) {
                                points[i].x = max(0, min(1, v.location.x / g.size.width))
                                points[i].y = max(0, min(1, 1 - v.location.y / g.size.height))
                                points.sort { $0.x < $1.x }
                            }
                        })
                }
            }
        }
    }
}
