import SwiftUI
import AppKit

/// Piano roll: create, select, multi-select, move, resize, zoom. Candidate notes are preview-only.
struct PianoRollCanvas: View {
    @Binding var pattern: Pattern
    @Binding var selectedPitch: Int
    @Binding var selectedNoteID: UUID?
    @Binding var selectedNoteIDs: Set<UUID>
    var candidate: Pattern?

    @State private var zoom: Double = 1.0

    private let baseBeatWidth: CGFloat = 72
    private let rowHeight: CGFloat = 22
    private let lowestPitch = 36
    private let highestPitch = 84
    private let snap: Double = 0.25

    private var beatWidth: CGFloat { baseBeatWidth * zoom }

    private var canvasWidth: CGFloat {
        CGFloat(max(pattern.lengthBeats, candidate?.lengthBeats ?? 0, 8)) * beatWidth + 40
    }

    private var canvasHeight: CGFloat {
        CGFloat(highestPitch - lowestPitch + 1) * rowHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("PIANO ROLL")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Zoom")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(value: $zoom, in: 0.5...2.5, step: 0.25)
                    .frame(width: 120)
                Text(String(format: "%.0f%%", zoom * 100))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
                Spacer()
                Text("Double-click empty cell to add · drag note to move · drag right edge to resize")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.04))

            GeometryReader { _ in
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .topLeading) {
                        grid
                            .contentShape(Rectangle())
                            .gesture(
                                SpatialTapGesture(count: 2).onEnded { value in
                                    addNote(at: value.location)
                                }
                            )

                        if let candidate {
                            ForEach(candidate.notes) { note in
                                PianoNoteCell(
                                    note: note,
                                    beatWidth: beatWidth,
                                    rowHeight: rowHeight,
                                    isSelected: false,
                                    isCandidate: true,
                                    onMove: { _ in },
                                    onResize: { _ in }
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
                                onMove: { delta in move(noteID: note.id, delta: delta) },
                                onResize: { deltaWidth in resize(noteID: note.id, deltaWidth: deltaWidth) }
                            )
                            .position(
                                x: note.startBeat * beatWidth + note.durationBeats * beatWidth / 2,
                                y: CGFloat(highestPitch - note.pitch) * rowHeight + rowHeight / 2
                            )
                            .onTapGesture {
                                if NSEvent.modifierFlags.contains(.command) {
                                    if selectedNoteIDs.contains(note.id) {
                                        selectedNoteIDs.remove(note.id)
                                    } else {
                                        selectedNoteIDs.insert(note.id)
                                    }
                                    selectedNoteID = note.id
                                    selectedPitch = note.pitch
                                } else {
                                    selectedNoteID = note.id
                                    selectedNoteIDs = [note.id]
                                    selectedPitch = note.pitch
                                }
                            }
                        }
                    }
                    .frame(width: canvasWidth, height: canvasHeight, alignment: .topLeading)
                }
            }
        }
    }

    private var grid: some View {
        Canvas { context, size in
            for pitch in lowestPitch...highestPitch {
                let y = CGFloat(highestPitch - pitch) * rowHeight
                let isC = pitch % 12 == 0
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: rowHeight)),
                    with: .color(isC ? Color.secondary.opacity(0.12) : Color.secondary.opacity(0.04))
                )
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y + rowHeight))
                        p.addLine(to: CGPoint(x: size.width, y: y + rowHeight))
                    },
                    with: .color(Color.secondary.opacity(0.15)),
                    lineWidth: 1
                )
            }
            let beats = Int(ceil(Double(size.width / beatWidth)))
            for beat in 0...beats {
                let x = CGFloat(beat) * beatWidth
                let isBar = beat % 4 == 0
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(Color.secondary.opacity(isBar ? 0.35 : 0.12)),
                    lineWidth: isBar ? 1.5 : 1
                )
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
    }

    private func move(noteID: UUID, delta: CGSize) {
        let ids: Set<UUID> = (!selectedNoteIDs.isEmpty && selectedNoteIDs.contains(noteID))
            ? selectedNoteIDs : [noteID]
        for id in ids {
            guard let index = pattern.notes.firstIndex(where: { $0.id == id }) else { continue }
            var n = pattern.notes[index]
            n.startBeat = max(
                0,
                min(pattern.lengthBeats - n.durationBeats, snapBeat(n.startBeat + Double(delta.width) / Double(beatWidth)))
            )
            n.pitch = max(
                lowestPitch,
                min(highestPitch, Int((Double(n.pitch) - Double(delta.height) / Double(rowHeight)).rounded()))
            )
            pattern.notes[index] = n
            if id == noteID {
                selectedNoteID = noteID
                selectedPitch = n.pitch
            }
        }
    }

    private func resize(noteID: UUID, deltaWidth: CGFloat) {
        guard let index = pattern.notes.firstIndex(where: { $0.id == noteID }) else { return }
        var note = pattern.notes[index]
        let deltaBeats = Double(deltaWidth) / Double(beatWidth)
        let newDuration = max(snap, min(pattern.lengthBeats - note.startBeat, snapBeat(note.durationBeats + deltaBeats)))
        note.durationBeats = max(snap, newDuration)
        if note.startBeat + note.durationBeats > pattern.lengthBeats {
            note.durationBeats = max(snap, pattern.lengthBeats - note.startBeat)
        }
        pattern.notes[index] = note
        selectedNoteID = noteID
        selectedNoteIDs = [noteID]
    }

    private func addNote(at location: CGPoint) {
        let beat = max(0, min(pattern.lengthBeats - 0.5, snapBeat(Double(location.x) / Double(beatWidth))))
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
    let onMove: (CGSize) -> Void
    let onResize: (CGFloat) -> Void

    @State private var moveStart: CGSize = .zero
    @State private var resizeStart: CGFloat = 0

    private var noteWidth: CGFloat { max(12, note.durationBeats * beatWidth - 2) }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isCandidate
                        ? Color.orange.opacity(0.55)
                        : (isSelected ? Color.accentColor : Color.accentColor.opacity(0.7))
                )
                .frame(width: noteWidth, height: rowHeight - 3)
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
                            onMove(CGSize(
                                width: value.translation.width - moveStart.width,
                                height: value.translation.height - moveStart.height
                            ))
                            moveStart = value.translation
                        }
                        .onEnded { _ in moveStart = .zero }
                )

            if !isCandidate {
                Rectangle()
                    .fill(Color.white.opacity(isSelected ? 0.85 : 0.35))
                    .frame(width: 5, height: rowHeight - 5)
                    .padding(.trailing, 1)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let delta = value.translation.width - resizeStart
                                onResize(delta)
                                resizeStart = value.translation.width
                            }
                            .onEnded { _ in resizeStart = 0 }
                    )
                    .help("Drag to resize duration")
            }
        }
        .frame(width: noteWidth, height: rowHeight - 3)
    }
}
