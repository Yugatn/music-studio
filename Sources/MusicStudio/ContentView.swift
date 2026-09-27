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

                TextField("Describe a melody or change…", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button(isGenerating ? "Generating…" : "Generate") {
                    generate()
                }
                .disabled(isGenerating)

                Button(showCurveEditor ? "Hide Curves" : "Curves") { showCurveEditor.toggle() }

                Button("Export MIDI") {
                    exportMIDI()
                }

                Spacer()
            }
            .padding(12)

            Divider()

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("TRACK")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(project.tracks.first?.name ?? "No track")
                        .font(.headline)

                    Divider()

                    Text("SELECTED NOTE")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Pitch", selection: $selectedPitch) {
                        ForEach(36...84, id: \.self) { pitch in
                            Text(noteName(pitch)).tag(pitch)
                        }
                    }
                    .onChange(of: selectedPitch) { _, newPitch in
                        updateSelectedPitch(newPitch)
                    }

                    HStack {
                        Button("Undo") { undo() }.disabled(history.isEmpty)
                        Button("Redo") { redo() }.disabled(future.isEmpty)
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
                        Button("Delete note", role: .destructive) {
                            deleteSelectedNote()
                        }
                    }

                    if selectedNoteID != nil {
                        Button("Duplicate note") {
                            duplicateSelectedNote()
                        }
                    }

                    Text("Drag a note to change pitch and timing. Double-click an empty grid cell to create a note.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(16)
                .frame(width: 220)

                Divider()

                PianoRollView(
                    pattern: patternBinding,
                    selectedPitch: $selectedPitch,
                    selectedNoteID: $selectedNoteID
                )
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
        guard let existing = project.tracks.first?.pattern, !existing.notes.isEmpty else { return }
        let points = currentCurve
        mutate { p in
            guard var pattern = p.tracks[0].pattern else { return }
            for i in pattern.notes.indices {
                let x = pattern.notes[i].startBeat / max(0.001, pattern.lengthBeats)
                let v = interpolate(points, x: x)
                switch curveMode {
                case .velocity: pattern.notes[i].velocity = max(1, min(127, Int((v * 126 + 1).rounded())))
                case .pitch: pattern.notes[i].pitch = max(24, min(108, pattern.notes[i].pitch + Int(((v - 0.5) * 12).rounded())))
                case .timing: pattern.notes[i].startBeat = max(0, min(pattern.lengthBeats - pattern.notes[i].durationBeats, pattern.notes[i].startBeat + (v - 0.5) * 0.5))
                case .expression: break
                }
            }
            p.tracks[0].pattern = pattern
        }
    }

    private var currentCurve: [CurvePoint] {
        switch curveMode { case .velocity: return curves.velocity; case .expression: return curves.expression; case .pitch: return curves.pitch; case .timing: return curves.timing }
    }

    private func interpolate(_ points: [CurvePoint], x: Double) -> Double {
        guard let first = points.first, let last = points.last else { return 0.5 }
        if x <= first.x { return first.y }; if x >= last.x { return last.y }
        for i in 1..<points.count where x <= points[i].x {
            let a=points[i-1], b=points[i], t=(x-a.x)/max(0.0001,b.x-a.x); return a.y+(b.y-a.y)*t
        }
        return 0.5
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
            get: {
                project.tracks.first?.pattern ?? Pattern(name: "Empty", lengthBeats: 8)
            },
            set: { newPattern in
                guard !project.tracks.isEmpty else { return }
                project.tracks[0].pattern = newPattern
            }
        )
    }

    private func generate() {
        isGenerating = true
        let request = MelodyRequest(
            prompt: prompt,
            bpm: project.bpm,
            key: project.key,
            scale: project.scale,
            bars: 2
        )

        Task {
            let candidate = try? await composer.generateMelody(request)
            if let candidate, !project.tracks.isEmpty {
                project.tracks[0].pattern = candidate
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
        guard let selectedNoteID,
              var pattern = project.tracks.first?.pattern,
              let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID })
        else { return }

        mutate { p in
            guard var pattern = p.tracks.first?.pattern,
                  let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
            pattern.notes[index].pitch = pitch
            p.tracks[0].pattern = pattern
        }
    }

    private func duplicateSelectedNote() {
        guard let selectedNoteID,
              var pattern = project.tracks.first?.pattern,
              let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
        var copy = pattern.notes[index]
        copy = NoteEvent(
            pitch: copy.pitch,
            startBeat: min(pattern.lengthBeats - copy.durationBeats, copy.startBeat + 0.5),
            durationBeats: copy.durationBeats,
            velocity: copy.velocity,
            channel: copy.channel
        )
        pattern.notes.append(copy)
        project.tracks[0].pattern = pattern
        self.selectedNoteID = copy.id
    }

    private func deleteSelectedNote() {
        guard let selectedNoteID,
              var pattern = project.tracks.first?.pattern
        else { return }

        pattern.notes.removeAll { $0.id == selectedNoteID }
        project.tracks[0].pattern = pattern
        self.selectedNoteID = nil
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
                    grid
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { value in addNote(at: value.location) }
                        )

                    ForEach(pattern.notes) { note in
                        NoteCell(
                            note: note,
                            beatWidth: beatWidth,
                            rowHeight: rowHeight,
                            isSelected: selectedNoteID == note.id
                        ) { delta in
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
                .frame(
                    width: CGFloat(pattern.lengthBeats) * beatWidth,
                    height: CGFloat(highestPitch - lowestPitch + 1) * rowHeight
                )
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
                context.stroke(
                    path,
                    with: .color(.secondary.opacity(beat % 4 == 0 ? 0.55 : 0.22))
                )
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

    private func snapBeat(_ beat: Double) -> Double {
        (beat / snap).rounded() * snap
    }
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
            .frame(
                width: max(12, note.durationBeats * beatWidth - 2),
                height: rowHeight - 3
            )
            .overlay {
                Text("\(note.pitch)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        move(CGSize(
                            width: value.translation.width - dragStart.width,
                            height: value.translation.height - dragStart.height
                        ))
                        dragStart = value.translation
                    }
                    .onEnded { _ in
                        dragStart = .zero
                    }
            )
    }
}

private enum CurveMode: String, CaseIterable, Identifiable { case velocity, expression, pitch, timing; var id: Self { self }; var title: String { rawValue.capitalized } }
private struct CurvePoint: Identifiable { let id=UUID(); var x: Double; var y: Double }
private struct CurveSet { var velocity:[CurvePoint]; var expression:[CurvePoint]; var pitch:[CurvePoint]; var timing:[CurvePoint]; static let standard=CurveSet(velocity:[CurvePoint(x:0,y:0.7),CurvePoint(x:0.5,y:0.45),CurvePoint(x:1,y:0.8)],expression:[CurvePoint(x:0,y:0.5),CurvePoint(x:1,y:0.5)],pitch:[CurvePoint(x:0,y:0.5),CurvePoint(x:1,y:0.5)],timing:[CurvePoint(x:0,y:0.5),CurvePoint(x:1,y:0.5)]) }
private struct CurveEditorView: View { @Binding var points:[CurvePoint]; var body: some View { GeometryReader { g in ZStack { RoundedRectangle(cornerRadius:8).fill(.quaternary.opacity(0.3)); Path { p in guard let f=points.first else{return}; p.move(to:CGPoint(x:f.x*g.size.width,y:(1-f.y)*g.size.height)); for q in points.dropFirst(){p.addLine(to:CGPoint(x:q.x*g.size.width,y:(1-q.y)*g.size.height))} }.stroke(.accent,lineWidth:2); ForEach(points){q in Circle().fill(.accent).frame(width:10,height:10).position(x:q.x*g.size.width,y:(1-q.y)*g.size.height).gesture(DragGesture().onChanged{v in if let i=points.firstIndex(where:{$0.id==q.id}){points[i].x=max(0,min(1,v.location.x/g.size.width));points[i].y=max(0,min(1,1-v.location.y/g.size.height));points.sort{$0.x<$1.x}}}) } } } } }
