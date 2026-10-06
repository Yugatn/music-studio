import XCTest
import MusicStudioCore

final class CompositionPresetTests: XCTestCase {
    func testPresetIDsAreUnique() {
        let ids = CompositionPresets.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testPresetsProvideActionableMusicalGuidance() {
        XCTAssertGreaterThanOrEqual(CompositionPresets.all.count, 3)
        for preset in CompositionPresets.all {
            XCTAssertFalse(preset.title.isEmpty)
            XCTAssertFalse(preset.instrumentation.isEmpty)
            XCTAssertFalse(preset.arrangementNotes.isEmpty)
            XCTAssertFalse(preset.promptTemplate.isEmpty)
            XCTAssertTrue(preset.instrumentalByDefault)
        }
    }

    func testShamanicPresetKeepsPercussionDominantAndVocalsOffByDefault() {
        let preset = CompositionPresets.preset(id: "shamanic-cinematic")
        XCTAssertNotNil(preset)
        XCTAssertTrue(preset?.instrumentation.first?.contains("drums") == true)
        XCTAssertTrue(preset?.promptTemplate.contains("No lead vocals") == true)
        XCTAssertTrue(preset?.avoid.contains(where: { $0.localizedCaseInsensitiveContains("vocals") }) == true)
    }

    func testPresetCanRoundTripThroughCodable() throws {
        let preset = try XCTUnwrap(CompositionPresets.preset(id: "dark-matrix-ambient"))
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(CompositionPreset.self, from: data)
        XCTAssertEqual(decoded.id, preset.id)
        XCTAssertEqual(decoded.promptTemplate, preset.promptTemplate)
        XCTAssertEqual(decoded.instrumentation, preset.instrumentation)
    }
}
