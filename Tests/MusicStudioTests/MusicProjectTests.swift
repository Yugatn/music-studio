import XCTest
@testable import MusicStudio

final class MusicProjectTests: XCTestCase {
    func testDemoProjectContainsEditableNotes() {
        let project = MusicProject.demo
        let notes = project.tracks.first?.pattern?.notes ?? []
        XCTAssertEqual(notes.count, 7)
        XCTAssertEqual(notes.first?.pitch, 60)
    }

    func testNoteEventIsCodable() throws {
        let note = NoteEvent(pitch: 64, startBeat: 1.5, durationBeats: 0.5, velocity: 90)
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(NoteEvent.self, from: data)
        XCTAssertEqual(note, decoded)
    }
}
