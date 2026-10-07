import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MusicStudioCore

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
    @State private var selectedNoteIDs: Set<UUID> = []
    @State private var showCandidateOverlay = true
    @State private var isGenerating = false
    private let composer = DemoAIComposer()
    @StateObject private var agentOrchestrator = AIAgentOrchestrator()
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
    @State private var showBrowser = false
    @State private var showInspector = true

    private var noteCount: Int { project.tracks.first?.pattern?.notes.count ?? 0 }
    private var stagedCandidate: Pattern? { agentOrchestrator.session.pendingCandidate ?? aiCandidate }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                    .onReceive(NotificationCenter.default.publisher(for: .openMIDIFile)) { _ in openMIDI() }
                    .onReceive(NotificationCenter.default.publisher(for: .openProjectFile)) { _ in openProject() }
                    .onReceive(NotificationCenter.default.publisher(for: .saveProjectFile)) { _ in saveProject() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.setModeCompose)) { _ in workspaceMode = .compose }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.setModeEdit)) { _ in workspaceMode = .edit }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.setModeAI)) { _ in workspaceMode = .ai }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.toggleBrowser)) { _ in showBrowser.toggle() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.toggleInspector)) { _ in showInspector.toggle() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.toggleCurves)) { _ in showCurveEditor.toggle() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.commandPalette)) { _ in showCommandPalette = true }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.quantize)) { _ in quantizeSelectedOrAll(grid: 0.25) }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.humanize)) { _ in humanizeNotes() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.selectAllNotes)) { _ in selectAllNotes() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.acceptCandidate)) { _ in acceptAgentCandidate() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.rejectCandidate)) { _ in agentOrchestrator.rejectPending(); aiCandidate = nil }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.generate)) { _ in generateWithAgent() }
                    .onReceive(NotificationCenter.default.publisher(for: StudioShortcut.transform)) { _ in reworkWithAgent() }

                StudioChrome(
                    projectName: $project.name,
                    bpm: $project.bpm,
                    isPlaying: $isPlaying,
                    workspaceMode: $workspaceMode,
                    key: project.key,
                    scale: project.scale,
                    noteCount: noteCount,
                    selectionCount: selectedNoteIDs.count,
                    hasCandidate: stagedCandidate != nil,
                    isGenerating: isGenerating,
                    canUndo: !history.isEmpty,
                    canRedo: !future.isEmpty,
                    onUndo: undo,
                    onRedo: redo,
                    onCommandPalette: { showCommandPalette = true },
                    onToggleBrowser: { showBrowser.toggle() },
                    onToggleInspector: { showInspector.toggle() }
                )

                HStack(spacing: 0) {
                    if showBrowser {
                        StudioBrowserPanel()
                            .frame(width: 180)
                        Divider()
                    }

                    VStack(spacing: 0) {
                        ArrangementStrip(
                            pattern: project.tracks.first?.pattern ?? Pattern(name: "Empty", lengthBeats: 8),
                            candidate: showCandidateOverlay ? stagedCandidate : nil,
                            bpm: project.bpm
                        )
                        Divider()

                        if workspaceMode != .edit {
                            HStack(spacing: 8) {
                                TextField("Describe a melody or change…", text: $prompt)
                                    .textFieldStyle(.roundedBorder)
                                Button(isGenerating ? "Working…" : "Generate") { generateWithAgent() }
                                    .disabled(isGenerating)
                                Button("Rework after edits") { reworkWithAgent() }
                                    .disabled(isGenerating || noteCount == 0)
                                    .help("Agent starts from your current melody")
                                Button(showCurveEditor ? "Hide Curves" : "Curves") { showCurveEditor.toggle() }
                                Button("Export MIDI") { exportMIDI() }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            Divider()
                        }

                        PianoRollCanvas(
                            pattern: patternBinding,
                            selectedPitch: $selectedPitch,
                            selectedNoteID: $selectedNoteID,
                            selectedNoteIDs: $selectedNoteIDs,
                            candidate: showCandidateOverlay ? stagedCandidate : nil
                        )
                    }

                    if showInspector {
                        Divider()
                        ScrollView {
                            inspector
                                .padding(16)
                        }
                        .frame(width: workspaceMode == .edit ? 280 : 260)
                    }
                }
            }

            if showCommandPalette {
                Color.black.opacity(0.25).ignoresSafeArea()
                    .onTapGesture { showCommandPalette = false }
                CommandPaletteView(isPresented: $showCommandPalette, commands: studioCommands)
            }
        }
        .onChange(of: workspaceMode) { _, mode in
            switch mode {
            case .edit: showInspector = true; showBrowser = false
            case .ai: showInspector = true
            case .compose: break
            }
        }
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRACK").font(.caption).foregroundStyle(.secondary)
            Text(project.tracks.first?.name ?? "No track").font(.headline)
            Divider()
            Text(selectedNoteIDs.isEmpty ? "SELECTED NOTE" : "SELECTED (\(selectedNoteIDs.count))")
                .font(.caption).foregroundStyle(.secondary)
            Picker("Pitch", selection: $selectedPitch) {
                ForEach(36...84, id: \.self) { Text(noteName($0)).tag($0) }
            }
            .onChange(of: selectedPitch) { _, newPitch in updateSelectedPitch(newPitch) }

            if selectedNoteID != nil || !selectedNoteIDs.isEmpty {
                HStack { Text("Velocity"); Slider(value: selectedVelocityBinding, in: 1...127, step: 1) }
                HStack { Text("Duration"); Slider(value: selectedDurationBinding, in: 0.25...4, step: 0.25) }
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
                CurveEditorView(points: curveBinding).frame(height: 140)
                Button("Apply curve") { applyCurve() }
            }

            if selectedNoteID != nil || !selectedNoteIDs.isEmpty {
                Button("Delete", role: .destructive) { deleteSelectedNote() }.keyboardShortcut(.delete, modifiers: [])
                Button("Duplicate") { duplicateSelectedNote() }.keyboardShortcut("d", modifiers: [.command])
                Button("Transpose +1") { transposeSelected(semitones: 1) }
                Button("Transpose −1") { transposeSelected(semitones: -1) }
                Button("Deselect") { clearSelection() }
            }

            Button("Quantize 1/16") { quantizeSelectedOrAll(grid: 0.25) }
            Button("Humanize") { humanizeNotes() }

            if workspaceMode == .ai || workspaceMode == .compose {
                Divider()
                AIAgentPanel(
                    orchestrator: agentOrchestrator,
                    project: project,
                    currentPattern: project.tracks.first?.pattern,
                    prompt: prompt,
                    isBusy: isGenerating,
                    onGenerate: { generateWithAgent() },
                    onRework: { reworkWithAgent() },
                    onContinue: { continueWithAgent() },
                    onAccept: { acceptAgentCandidate() },
                    onReject: { agentOrchestrator.rejectPending(); aiCandidate = nil }
                )
            }

            if stagedCandidate != nil {
                Toggle("Show candidate overlay", isOn: $showCandidateOverlay).font(.caption)
            }

            Divider()
            Text("NOTES / TAGS").font(.caption).foregroundStyle(.secondary)
            TextField("New note", text: $projectNoteDraft)
            Button("Add note") { addProjectNote() }
                .disabled(projectNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ForEach(project.metadata.notes.suffix(4)) { note in
                Text((note.title.isEmpty ? note.text : note.title).prefix(48))
                    .font(.caption2).lineLimit(1)
            }
            TextField("Add tag", text: $tagDraft)
            Button("Add tag") { addTag() }
                .disabled(tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Text("Loop: Generate → edit notes → Rework after edits → Accept/Reject")
                .font(.caption2).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var studioCommands: [StudioCommand] {
        [
            StudioCommand(id: "undo", title: "Undo", action: undo),
            StudioCommand(id: "redo", title: "Redo", action: redo),
            StudioCommand(id: "generate", title: "Generate (agent)", action: generateWithAgent),
            StudioCommand(id: "rework", title: "Rework After Subject Edits", action: reworkWithAgent),
            StudioCommand(id: "continue", title: "Agent Continue Independently", action: continueWithAgent),
            StudioCommand(id: "accept", title: "Accept Candidate", action: acceptAgentCandidate),
            StudioCommand(id: "reject", title: "Reject Candidate", action: { agentOrchestrator.rejectPending(); aiCandidate = nil }),
            StudioCommand(id: "quantize", title: "Quantize 1/16", action: { quantizeSelectedOrAll(grid: 0.25) }),
            StudioCommand(id: "humanize", title: "Humanize", action: humanizeNotes),
            StudioCommand(id: "mode-compose", title: "Mode: Compose", action: { workspaceMode = .compose }),
            StudioCommand(id: "mode-edit", title: "Mode: Edit", action: { workspaceMode = .edit }),
            StudioCommand(id: "mode-ai", title: "Mode: AI", action: { workspaceMode = .ai }),
            StudioCommand(id: "save", title: "Save Project…", action: saveProject),
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
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url),
           let imported = try? MIDIFileImporter.importProject(data: data, name: url.deletingPathExtension().lastPathComponent) {
            project = imported; clearSelection(); history.removeAll(); future.removeAll(); aiCandidate = nil
        }
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.musicStudioProject]
        if panel.runModal() == .OK, let url = panel.url, let loaded = try? ProjectFile.load(from: url) {
            project = loaded; clearSelection(); history.removeAll(); future.removeAll(); aiCandidate = nil
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
                agentOrchestrator.noteSubjectEdit(pattern: newPattern, projectID: project.id)
            }
        )
    }

    private func generateWithAgent() {
        isGenerating = true
        workspaceMode = .ai
        Task {
            if let result = await agentOrchestrator.generateIndependent(project: project, prompt: prompt) {
                aiCandidate = result.pattern
            }
            isGenerating = false
        }
    }

    private func reworkWithAgent() {
        guard let pattern = project.tracks.first?.pattern, !pattern.notes.isEmpty else { return }
        isGenerating = true
        workspaceMode = .ai
        agentOrchestrator.noteSubjectEdit(pattern: pattern, projectID: project.id)
        Task {
            if let result = await agentOrchestrator.reworkAfterSubject(project: project, currentPattern: pattern, instruction: prompt) {
                aiCandidate = result.pattern
            }
            isGenerating = false
        }
    }

    private func continueWithAgent() {
        isGenerating = true
        workspaceMode = .ai
        Task {
            if let result = await agentOrchestrator.continueIndependent(project: project, prompt: prompt) {
                aiCandidate = result.pattern
            }
            isGenerating = false
        }
    }

    private func acceptAgentCandidate() {
        let candidate = agentOrchestrator.acceptPending() ?? aiCandidate
        guard let candidate else { return }
        mutate { p in
            guard !p.tracks.isEmpty else { return }
            p.tracks[0].pattern = candidate
        }
        aiCandidate = nil
        clearSelection()
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

    private func selectAllNotes() {
        selectedNoteIDs = Set(project.tracks.first?.pattern?.notes.map(\.id) ?? [])
        selectedNoteID = selectedNoteIDs.first
    }

    private func clearSelection() { selectedNoteID = nil; selectedNoteIDs.removeAll() }

    private func selectionFocusIDs() -> Set<UUID>? {
        if !selectedNoteIDs.isEmpty { return selectedNoteIDs }
        if let id = selectedNoteID { return [id] }
        return nil
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
        let ids = selectionFocusIDs() ?? []
        guard !ids.isEmpty else { return }
        mutate { p in
            guard var pattern = p.tracks.first?.pattern else { return }
            for i in pattern.notes.indices where ids.contains(pattern.notes[i].id) { pattern.notes[i].pitch = pitch }
            p.tracks[0].pattern = pattern
        }
    }

    private func duplicateSelectedNote() {
        guard let selectedNoteID, let pattern = project.tracks.first?.pattern,
              let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
        let source = pattern.notes[index]
        let copy = NoteEvent(pitch: source.pitch, startBeat: min(pattern.lengthBeats - source.durationBeats, source.startBeat + 0.5), durationBeats: source.durationBeats, velocity: source.velocity, channel: source.channel)
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            pat.notes.append(copy); p.tracks[0].pattern = pat
        }
        self.selectedNoteID = copy.id; selectedNoteIDs = [copy.id]
    }

    private func quantizeSelectedOrAll(grid: Double = 0.25) {
        let focus = selectionFocusIDs()
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            for i in pat.notes.indices {
                if let focus, !focus.contains(pat.notes[i].id) { continue }
                let snapped = (pat.notes[i].startBeat / grid).rounded() * grid
                pat.notes[i].startBeat = max(0, min(pat.lengthBeats - pat.notes[i].durationBeats, snapped))
            }
            p.tracks[0].pattern = pat
        }
    }

    private func humanizeNotes() {
        let focus = selectionFocusIDs()
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            for i in pat.notes.indices {
                if let focus, !focus.contains(pat.notes[i].id) { continue }
                pat.notes[i].startBeat = max(0, min(pat.lengthBeats - pat.notes[i].durationBeats, pat.notes[i].startBeat + Double.random(in: -0.04...0.04)))
                pat.notes[i].velocity = max(1, min(127, pat.notes[i].velocity + Int.random(in: -8...8)))
            }
            p.tracks[0].pattern = pat
        }
    }

    private func transposeSelected(semitones: Int) {
        let ids = selectionFocusIDs() ?? []
        guard !ids.isEmpty else { return }
        mutate { p in
            guard !p.tracks.isEmpty, var pat = p.tracks[0].pattern else { return }
            for i in pat.notes.indices where ids.contains(pat.notes[i].id) {
                pat.notes[i].pitch = max(24, min(108, pat.notes[i].pitch + semitones))
            }
            p.tracks[0].pattern = pat
        }
    }

    private func deleteSelectedNote() {
        let ids: Set<UUID> = !selectedNoteIDs.isEmpty ? selectedNoteIDs : (selectedNoteID.map { [$0] } ?? [])
        guard !ids.isEmpty else { return }
        mutate { p in
            guard !p.tracks.isEmpty, var pattern = p.tracks[0].pattern else { return }
            pattern.notes.removeAll { ids.contains($0.id) }
            p.tracks[0].pattern = pattern
        }
        clearSelection()
    }

    private var selectedVelocityBinding: Binding<Double> {
        Binding(
            get: {
                guard let id = selectedNoteID, let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == id }) else { return 96 }
                return Double(note.velocity)
            },
            set: { value in
                let v = Int(value.rounded()); let ids = selectionFocusIDs() ?? []
                mutate { p in
                    guard var pattern = p.tracks.first?.pattern else { return }
                    for i in pattern.notes.indices where ids.contains(pattern.notes[i].id) {
                        pattern.notes[i].velocity = max(1, min(127, v))
                    }
                    p.tracks[0].pattern = pattern
                }
            }
        )
    }

    private var selectedDurationBinding: Binding<Double> {
        Binding(
            get: {
                guard let id = selectedNoteID, let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == id }) else { return 0.5 }
                return note.durationBeats
            },
            set: { value in
                let ids = selectionFocusIDs() ?? []
                mutate { p in
                    guard var pattern = p.tracks.first?.pattern else { return }
                    for i in pattern.notes.indices where ids.contains(pattern.notes[i].id) {
                        pattern.notes[i].durationBeats = max(0.25, min(4, value))
                    }
                    p.tracks[0].pattern = pattern
                }
            }
        )
    }

    private func noteName(_ pitch: Int) -> String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
        return "\(names[pitch % 12])\(pitch / 12 - 1)"
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
                }.stroke(Color.accentColor, lineWidth: 2)
                ForEach(points) { q in
                    Circle().fill(Color.accentColor).frame(width: 10, height: 10)
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
