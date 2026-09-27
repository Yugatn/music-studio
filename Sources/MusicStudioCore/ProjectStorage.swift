import Foundation

public enum ProjectStorage {
    public static func save(project: MusicProject, to url: URL) throws {
        let data = try ProjectCodec.encode(project)
        try data.write(to: url, options: .atomic)
    }

    public static func load(from url: URL) throws -> MusicProject {
        let data = try Data(contentsOf: url)
        return try ProjectCodec.decode(data).project
    }
}
