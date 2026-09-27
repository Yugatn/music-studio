import Foundation

public struct ProjectNote: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var text: String
    public var beat: Double?
    public var trackID: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String = "", text: String, beat: Double? = nil, trackID: UUID? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id=id; self.title=title; self.text=text; self.beat=beat; self.trackID=trackID; self.createdAt=createdAt; self.updatedAt=updatedAt
    }
}

public struct ProjectMetadata: Codable, Equatable, Sendable {
    public var notes: [ProjectNote]
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(notes: [ProjectNote] = [], tags: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.notes=notes; self.tags=tags; self.createdAt=createdAt; self.updatedAt=updatedAt
    }
}

public enum ProjectMetadataEditing {
    public static func addNote(to metadata: inout ProjectMetadata, _ note: ProjectNote) {
        metadata.notes.append(note)
        metadata.updatedAt = Date()
    }

    public static func updateNote(_ noteID: UUID, in metadata: inout ProjectMetadata, title: String, text: String) {
        guard let index = metadata.notes.firstIndex(where: { $0.id == noteID }) else { return }
        metadata.notes[index].title = title
        metadata.notes[index].text = text
        metadata.notes[index].updatedAt = Date()
        metadata.updatedAt = Date()
    }

    public static func removeNote(_ noteID: UUID, from metadata: inout ProjectMetadata) {
        metadata.notes.removeAll { $0.id == noteID }
        metadata.updatedAt = Date()
    }
}
