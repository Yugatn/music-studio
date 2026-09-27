import Foundation

public enum MusicalChangeKind: String, Codable, Sendable {
    case velocity, timing, pitch, harmony, rhythm, density, register, structure, articulation
}

public struct MusicalChange: Codable, Identifiable, Sendable {
    public let id: UUID
    public let kind: MusicalChangeKind
    public let description: String
    public let intensity: Double
    public let scope: String

    public init(id: UUID = UUID(), kind: MusicalChangeKind, description: String, intensity: Double, scope: String = "project") {
        self.id=id; self.kind=kind; self.description=description; self.intensity=max(0,min(1,intensity)); self.scope=scope
    }
}

public struct AIChangePlan: Codable, Identifiable, Sendable {
    public let id: UUID
    public let sourceRevision: Int64?
    public let changes: [MusicalChange]

    public init(id: UUID = UUID(), sourceRevision: Int64? = nil, changes: [MusicalChange]) {
        self.id=id; self.sourceRevision=sourceRevision; self.changes=changes
    }
}
