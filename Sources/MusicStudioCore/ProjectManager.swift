import Foundation

public struct ProjectTemplate: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let bpm: Double
    public let key: String
    public let scale: String

    public init(id: String, name: String, bpm: Double, key: String, scale: String) {
        self.id=id; self.name=name; self.bpm=bpm; self.key=key; self.scale=scale
    }
}

public enum BuiltInProjectTemplates {
    public static let all: [ProjectTemplate] = [
        .init(id: "empty", name: "Empty", bpm: 120, key: "C", scale: "Major"),
        .init(id: "ai-melody", name: "AI Melody", bpm: 110, key: "C", scale: "Minor"),
        .init(id: "beat", name: "Beat", bpm: 120, key: "C", scale: "Minor"),
        .init(id: "song", name: "Song", bpm: 100, key: "C", scale: "Major"),
        .init(id: "ambient", name: "Ambient", bpm: 70, key: "D", scale: "Minor")
    ]
}

public struct RecentProject: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var url: URL
    public var lastOpened: Date
    public var isFavorite: Bool

    public init(id: UUID = UUID(), name: String, url: URL, lastOpened: Date = Date(), isFavorite: Bool = false) {
        self.id=id; self.name=name; self.url=url; self.lastOpened=lastOpened; self.isFavorite=isFavorite
    }
}

public struct ProjectManagerModel: Codable, Equatable, Sendable {
    public var recent: [RecentProject]

    public init(recent: [RecentProject] = []) {
        self.recent=recent
    }

    public mutating func opened(_ project: RecentProject) {
        recent.removeAll { $0.url == project.url }
        recent.insert(project, at: 0)
        recent = Array(recent.prefix(30))
    }
}
