import XCTest
@testable import MusicStudio

final class MIDIFileImporterTests: XCTestCase {
    func testPolyphonicImportKeepsSimultaneousPitches() throws {
        let project = MusicProject(
            name: "Poly",
            bpm: 120,
            key: "C",
            scale: "Major",
            tracks: [
                Track(
                    id: UUID(),
                    name: "MIDI",
                    kind: .instrument,
                    pattern: Pattern(
                        name: "P",
                        lengthBeats: 4,
                        notes: [
                            NoteEvent(pitch: 60, startBeat: 0, durationBeats: 1),
                            NoteEvent(pitch: 64, startBeat: 0, durationBeats: 1)
                        ]
                    )
                )
            ]
        )

        let midi = try MIDIFile.export(project: project)
        let imported = try MIDIFileImporter.importProject(data: midi)
        let notes = imported.tracks.first?.pattern?.notes ?? []

        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes.map(\.pitch), [60, 64])
    }

    func testImportReadsTempo() throws {
        var project = MusicProject.demo
        project.bpm = 90
        let midi = try MIDIFile.export(project: project)
        let imported = try MIDIFileImporter.importProject(data: midi)
        XCTAssertEqual(imported.bpm, 90, accuracy: 0.01)
    }

    func testExportThenImportPreservesNotes() throws {
        let original = MusicProject.demo
        let midi = try MIDIFile.export(project: original)
        let imported = try MIDIFileImporter.importProject(data: midi)

        let source = original.tracks.first?.pattern?.notes ?? []
        let result = imported.tracks.first?.pattern?.notes ?? []

        XCTAssertEqual(result.count, source.count)
        XCTAssertEqual(result.map(\.pitch), source.map(\.pitch))
        XCTAssertEqual(result.map(\.velocity), source.map(\.velocity))
        XCTAssertEqual(result.map { $0.startBeat }, source.map { $0.startBeat })
    }
}
