import SwiftUI
import AppKit
import UniformTypeIdentifiers

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

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 0)
                .onReceive(NotificationCenter.default.publisher(for: .openMIDIFile)) { _ in openMIDI() }
                .onReceive(NotificationCenter.default.publisher(for: .openProjectFile)) { _ in openProject() }
                .onReceive(NotificationCenter.default.publisher(for: .saveProjectFile)) { _ in saveProject() }
            HStack(spacing: 12) {
                Button { isPlaying.toggle() } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                .keyboardShortcut(.space, modifiers: [])
                .help("Transport flag only — audio engine not yet wired")

                TextField("Project", text: $project.name)
                    .frame(width: 150)

                Stepper("BPM \(Int(project.bpm))", value: $project.bpm, in: 40...240)
                    .frame(width: 125)

                Picker("Key", selection: $project.key) {
                    ForEach(["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .frame(width: 100)

                Picker("Scale", selection: $project.scale) {
                    ForEach(["Major", "Minor", "Pentatonic", "Minor Pentatonic"], id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 130)

                TextField("Describe a melody or change…", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button(isGenerating ? "Generating…" : "Generate") { generate() }
                    .disabled(isGenerating)

                Button(showCurveEditor ? "Hide Curves" : "Curves") { showCurveEditor.toggle() }
                Button("Export MIDI") { exportMIDI() }
                Spacer()
            }
            .padding(12)

            Divider()

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("TRACK").font(.caption).foregroundStyle(.secondary)
                    Text(project.tracks.first?.name ?? "No track").font(.headline)
                    Divider()
                    Text("SELECTED NOTE").font(.caption).foregroundStyle(.secondary)
                    Picker("Pitch", selection: $selectedPitch) {
                        ForEach(36...84, id: \.self) { pitch in Text(noteName(pitch)).tag(pitch) }
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

                    if showCurveEditor {
                        Divider()
                        Text("CURVE").font(.caption).foregroundStyle(.secondary)
                        Picker("Parameter", selection: $curveMode) {
                            ForEach(CurveMode.allCases) { Text($0.title).tag($0) }
                        }
                        CurveEditorView(points: curveBinding).frame(height: 180)
                        Button("Apply curve") { applyCurve() }
                    }

                    if selectedNoteID != nil {
                        Button("Delete note", role: .destructive) { deleteSelectedNote() }
                            .keyboardShortcut(.delete, modifiers: [])
                        Button("Duplicate note") { duplicateSelectedNote() }
                            .keyboardShortcut("d", modifiers: [.command])
                        Button("Transpose +1") { transposeSelected(semitones: 1) }
                        Button("Transpose −1") { transposeSelected(semitones: -1) }
                    }
                    Button("Quantize 1/16") { quantizeSelectedOrAll(grid: 0.25) }

                    Text("Drag a note to change pitch and timing. Double-click an empty grid cell to create a note.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(16).frame(width: 220)

                Divider()

                PianoRollView(pattern: patternBinding, selectedPitch: $selectedPitch, selectedNoteID: $selectedNoteID)
            }
        }
    }

    private var curveBinding: Binding<[CurvePoint]> {
        switch curveMode {
        case .velocity: return $curves.velocity
        case .expression: return $curves.expression
        case .pitch: return $curves.pitch
        case .timing: return $curves.timing
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

    private var currentCurve: [CurvePoint] {
        switch curveMode {
        case .velocity: return curves.velocity
        case .expression: return curves.expression
        case .pitch: return curves.pitch
        case .timing: return curves.timing
        }
    }

    private func exportMIDI() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.name).mid"
        panel.allowedContentTypes = [.midi]
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? MIDIFile.export(project: project) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func openMIDI() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.midi]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url),
           let imported = try? MIDIFileImporter.importProject(data: data, name: url.deletingPathExtension().lastPathComponent) {
            project = imported
            selectedNoteID = nil
        }
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.musicStudioProject]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let loaded = try? ProjectFile.load(from: url) {
            project = loaded
            selectedNoteID = nil
        }
    }

    private func saveProject() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.name).yms"
        panel.allowedContentTypes = [.musicStudioProject]
        if panel.runModal() == .OK, let url = panel.url {
            try? ProjectFile.save(project, to: url)
        }
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
            let candidate = try? await composer.generateMelody(request)
            if let candidate, !project.tracks.isEmpty {
                mutate { p in
                    guard !p.tracks.isEmpty else { return }
                    p.tracks[0].pattern = candidate
                }
                selectedNoteID = nil
            }
            isGenerating = false
        }
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
            guard var pattern = p.tracks.first?.pattern,
                  let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
            pattern.notes[index].pitch = pitch
            p.tracks[0].pattern = pattern
        }
    }

    private func duplicateSelectedNote() {
        guard let selectedNoteID,
              let pattern = project.tracks.first?.pattern,
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
            set: { value in updateSelectedVelocity(Int(value.rounded())) }
        )
    }

    private var selectedDurationBinding: Binding<Double> {
        Binding(
            get: {
                guard let id = selectedNoteID, let note = project.tracks.first?.pattern?.notes.first(where: { $0.id == id }) else { return 0.5 }
                return note.durationBeats
            },
            set: { value in updateSelectedDuration(value) }
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
                        .onTapGesture {
                            selectedNoteID = note.id
                            selectedPitch = note.pitch
                        }
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
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.secondary.opacity(beat % 4 == 0 ? 0.55 : 0.22)))
            }
            for row in 0...(highestPitch - lowestPitch) {
                let y = CGFloat(row) * rowHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.secondary.opacity(0.18)))
            }
        }
    }

    private func move(noteID: UUID, delta: CGSize) {
        guard let index = pattern.notes.firstIndex(where: { $0.id == noteID }) else { return }
        var note = pattern.notes[index]
        let rawBeat = note.startBeat + delta.width / beatWidth
        let rawPitch = Double(note.pitch) - delta.height / rowHeight
        note.startBeat = max(0, min(pattern.lengthBeats - note.durationBeats, snapBeat(rawBeat)))
        note.pitch = max(lowestPitch, min(highestPitch, Int(rawPitch.rounded())))
        pattern.notes[index] = note
        selectedNoteID = noteID
        selectedPitch = note.pitch
    }

    private func addNote(at location: CGPoint) {
        let beat = max(0, min(pattern.lengthBeats - 0.5, snapBeat(location.x / beatWidth)))
        let pitch = max(lowestPitch, min(highestPitch, highestPitch - Int(location.y / rowHeight)))
        let note = NoteEvent(pitch: pitch, startBeat: beat, durationBeats: 0.5, velocity: 96)
        pattern.notes.append(note)
        selectedNoteID = note.id
        selectedPitch = pitch
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
            .overlay {
                Text("\(note.pitch)").font(.system(size: 9, weight: .medium)).foregroundStyle(.white)
            }
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
