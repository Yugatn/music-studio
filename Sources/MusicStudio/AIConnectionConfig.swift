import Foundation

/// User-configurable connection to an external AI service.
/// Stored in Application Support (not in the project file).
struct AIConnectionConfig: Codable, Equatable, Sendable {
    var enabled: Bool
    var displayName: String
    /// Base URL, e.g. https://api.openai.com/v1 or a custom agent endpoint
    var baseURL: String
    /// Optional bearer token / API key (stored locally only)
    var apiKey: String
    var model: String
    /// Path relative to baseURL for compose calls
    var composePath: String
    var timeoutSeconds: Double

    static let `default` = AIConnectionConfig(
        enabled: false,
        displayName: "Remote AI",
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-4o-mini",
        composePath: "/chat/completions",
        timeoutSeconds: 60
    )

    private static var fileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = root.appendingPathComponent("MusicStudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ai-connection.json")
    }

    static func load() -> AIConnectionConfig {
        let url = fileURL
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AIConnectionConfig.self, from: data)
        else { return .default }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    /// Reject insecure remote endpoints when a credential is configured.
    /// Plain HTTP is only permitted for uncredentialed local loopback agents.
    var isReady: Bool {
        guard enabled,
              let components = URLComponents(
                string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
              ),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased(),
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.query == nil,
              components.fragment == nil
        else { return false }

        if scheme == "https" { return true }
        if scheme == "http", apiKey.isEmpty {
            return ["localhost", "127.0.0.1", "::1"].contains(host)
        }
        return false
    }
}
