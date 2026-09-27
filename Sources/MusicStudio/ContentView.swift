import SwiftUI

struct ContentView: View {
    @Binding var project: MusicProject
    @State private var isPlaying = false
    @State private var prompt = "melodic electronic intro, evolving but simple"
    @State private var selectedPitch = 60
    @State private var selectedNoteID: UUID?
    @State private var isGenerating = false
    private let composer = DemoAIComposer()

    var body: some View {
        VStack(spacing: 0) {
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

                    if selectedNoteID != nil {
                        Button("Delete note", role: .destructive) {
                            deleteSelectedNote()
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

    private func updateSelectedPitch(_ pitch: Int) {
        guard let selectedNoteID,
              var pattern = project.tracks.first?.pattern,
              let index = pattern.notes.firstIndex(where: { $0.id == selectedNoteID })
        else { return }

        pattern.notes[index].pitch = pitch
        project.tracks[0].pattern = pattern
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
