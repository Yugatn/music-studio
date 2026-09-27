import Foundation

public enum ProjectCodec {
    public static let currentVersion = 1

    private struct Envelope: Codable {
        let version: Int
        let project: MusicProject
    }

    public static func encode(_ project: MusicProject) throws -> Data {
        try JSONEncoder().encode(Envelope(version: currentVersion, project: project))
    }

    public static func decode(_ data: Data) throws -> MusicProject {
        try JSONDecoder().decode(Envelope.self, from: data).project
    }
}
