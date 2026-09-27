import XCTest
@testable import MusicStudio

final class MIDIFileTests: XCTestCase {
    func testExportCreatesStandardMIDIHeader() throws {
        let data = try MIDIFile.export(project: MusicProject.demo)
        XCTAssertEqual(Array(data.prefix(4)), Array("MThd".utf8))
        XCTAssertTrue(data.count > 20)
    }

    func testExportContainsTrackChunk() throws {
        let data = try MIDIFile.export(project: MusicProject.demo)
        let bytes = Array(data)
        XCTAssertTrue(bytes.windows(ofCount: 4).contains(Array("MTrk".utf8)))
    }
}

private extension Array where Element: Equatable {
    func windows(ofCount count: Int) -> [[Element]] {
        guard count > 0, count <= self.count else { return [] }
        return (0...(self.count - count)).map { Array(self[$0..<$0 + count]) }
    }
}
