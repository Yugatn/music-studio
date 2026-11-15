import XCTest
@testable import MusicStudio

final class AIConnectionConfigTests: XCTestCase {
    func testDisabledConnectionCannotMakeRequests() {
        var config = AIConnectionConfig.default
        config.enabled = false
        XCTAssertFalse(config.isReady)
    }

    func testHttpsRemoteConnectionAccepted() {
        var config = AIConnectionConfig.default
        config.enabled = true
        config.apiKey = "example-test-token"
        XCTAssertTrue(config.isReady)
    }

    func testRemoteHttpWithCredentialRejected() {
        var config = AIConnectionConfig.default
        config.enabled = true
        config.baseURL = "http://example.com/v1"
        config.apiKey = "example-test-token"
        XCTAssertFalse(config.isReady)
    }

    func testLocalHttpOnlyWithoutCredential() {
        var config = AIConnectionConfig.default
        config.enabled = true
        config.baseURL = "http://127.0.0.1:1234/v1"
        config.apiKey = ""
        XCTAssertTrue(config.isReady)
        config.apiKey = "example-test-token"
        XCTAssertFalse(config.isReady)
    }

    func testMalformedAndEmbeddedCredentialsRejected() {
        var config = AIConnectionConfig.default
        config.enabled = true
        config.baseURL = "not-a-url"
        XCTAssertFalse(config.isReady)
        config.baseURL = "https://user:password@example.com/v1"
        XCTAssertFalse(config.isReady)
    }
}
