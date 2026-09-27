import Foundation

public enum ProjectCodec {
    public static let currentVersion = 2

    private struct Envelope: Codable {
        let version: Int
        let project: MusicProject
        let metadata: ProjectMetadata
    }

    public static func encode(_ project: MusicProject, metadata: ProjectMetadata = ProjectMetadata()) throws -> Data {
        try JSONEncoder().encode(Envelope(version: currentVersion, project: project, metadata: metadata))
    }

    public static func decode(_ data: Data) throws -> (project: MusicProject, metadata: ProjectMetadata) {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(Envelope.self, from: data) {
            return (envelope.project, envelope.metadata)
        }
        struct LegacyProject: Codable { let id: UUID; let name: String; let bpm: Double; let key: String; let scale: String; let tracks: [Track] }
        let legacy = try decoder.decode(LegacyProject.self, from: data)
        return (MusicProject(id: legacy.id, name: legacy.name, bpm: legacy.bpm, key: legacy.key, scale: legacy.scale, tracks: legacy.tracks), ProjectMetadata())
    }
}
