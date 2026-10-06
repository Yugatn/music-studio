import SwiftUI

/// Piano roll canvas with multi-select (Cmd-click) and optional AI candidate ghost notes.
struct PianoRollCanvas: View {
    @Binding var pattern: Pattern
    @Binding var selectedPitch: Int
    @Binding var selectedNoteID: UUID?
    @Binding var selectedNoteIDs: Set<UUID>
    var candidate: Pattern?

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

                    if let candidate {
                        ForEach(candidate.notes) { note in
                            PianoNoteCell(
                                note: note,
                                beatWidth: beatWidth,
                                rowHeight: rowHeight,
                                isSelected: false,
                                isCandidate: true,
                                move: { _ in }
                            )
                            .position(
                                x: note.startBeat * beatWidth + note.durationBeats * beatWidth / 2,
                                y: CGFloat(highestPitch - note.pitch) * rowHeight + rowHeight / 2
                            )
                            .allowsHitTesting(false)
                        }
                    }

                    ForEach(pattern.notes) { note in
                        PianoNoteCell(
                            note: note,
                            beatWidth: beatWidth,
                            rowHeight: rowHeight,
                            isSelected: selectedNoteIDs.contains(note.id) || selectedNoteID == note.id,
                            isCandidate: false,
                            move: { delta in move(noteID: note.id, delta: delta) }
                        )
                        .position(
                            x: note.startBeat * beatWidth + note.durationBeats * beatWidth / 2,
                            y: CGFloat(highestPitch - note.pitch) * rowHeight + rowHeight / 2
                        )
                        .onTapGesture {
                            selectedNoteID = note.id
                            selectedPitch = note.pitch
                            selectedNoteIDs = [note.id]
                        }
                        .simultaneousGesture(
                            TapGesture().modifiers(.command).onEnded {
                                if selectedNoteIDs.contains(note.id) {
                                    selectedNoteIDs.remove(note.id)
                                } else {
                                    selectedNoteIDs.insert(note.id)
                                }
                                selectedNoteID = note.id
                                selectedPitch = note.pitch
                            }
                        )
                    }
                }
                .frame(
                    width: CGFloat(max(pattern.lengthBeats, candidate?.lengthBeats ?? 0)) * beatWidth,
                    height: CGFloat(highestPitch - lowestPitch + 1) * rowHeight
                )
                .padding(30)
            }
        }
    }

    private var grid: some View {
        Canvas { context, size in
            let beats = Int(max(pattern.lengthBeats, candidate?.lengthBeats ?? 0))
            for beat in 0...beats {
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
        let ids: Set<UUID> = (!selectedNoteIDs.isEmpty && selectedNoteIDs.contains(noteID))
            ? selectedNoteIDs : [noteID]
        for id in ids {
            guard let index = pattern.notes.firstIndex(where: { $0.id == id }) else { continue }
            var note = pattern.notes[index]
            note.startBeat = max(
                0,
                min(pattern.lengthBeats - note.durationBeats, snapBeat(note.startBeat + delta.width / beatWidth))
            )
            note.pitch = max(
                lowestPitch,
                min(highestPitch, Int((Double(note.pitch) - delta.height / rowHeight).rounded()))
            )
            pattern.notes[index] = note
            if id == noteID {
                selectedNoteID = noteID
                selectedPitch = note.pitch
            }
        }
    }

    private func addNote(at location: CGPoint) {
        let beat = max(0, min(pattern.lengthBeats - 0.5, snapBeat(location.x / beatWidth)))
        let pitch = max(lowestPitch, min(highestPitch, highestPitch - Int(location.y / rowHeight)))
        let note = NoteEvent(pitch: pitch, startBeat: beat, durationBeats: 0.5, velocity: 96)
        pattern.notes.append(note)
        selectedNoteID = note.id
        selectedNoteIDs = [note.id]
        selectedPitch = pitch
    }

    private func snapBeat(_ beat: Double) -> Double { (beat / snap).rounded() * snap }
}

private struct PianoNoteCell: View {
    let note: NoteEvent
    let beatWidth: CGFloat
    let rowHeight: CGFloat
    let isSelected: Bool
    var isCandidate: Bool = false
    let move: (CGSize) -> Void
    @State private var dragStart: CGSize = .zero

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                isCandidate
                    ? Color.orange.opacity(0.55)
                    : (isSelected ? Color.accentColor : Color.accentColor.opacity(0.7))
            )
            .frame(width: max(12, note.durationBeats * beatWidth - 2), height: rowHeight - 3)
            .overlay {
                Text("\(note.pitch)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isCandidate ? Color.primary.opacity(0.55) : Color.white)
            }
            .opacity(isCandidate ? 0.45 : 1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isCandidate else { return }
                        move(CGSize(
                            width: value.translation.width - dragStart.width,
                            height: value.translation.height - dragStart.height
                        ))
                        dragStart = value.translation
                    }
                    .onEnded { _ in dragStart = .zero }
            )
    }
}
