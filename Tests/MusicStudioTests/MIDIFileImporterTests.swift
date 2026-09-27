import XCTest
@testable import MusicStudio

final class MIDIFileImporterTests: XCTestCase {
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
