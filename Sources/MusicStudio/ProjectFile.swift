import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var musicStudioProject: UTType {
        UTType(exportedAs: "com.yugatn.music-studio.project", conformingTo: .data)
    }
}

enum ProjectFile {
    static func save(_ project: MusicProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(project).write(to: url, options: .atomic)
    }

    static func load(from url: URL) throws -> MusicProject {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(MusicProject.self, from: data)
    }
}
