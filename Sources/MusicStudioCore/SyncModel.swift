import Foundation

public struct ProjectRevision: Codable, Equatable, Sendable {
    public let projectID: UUID
    public let revision: Int64
    public let deviceID: String
    public let timestamp: Date

    public init(projectID: UUID, revision: Int64, deviceID: String, timestamp: Date = Date()) {
        self.projectID=projectID; self.revision=revision; self.deviceID=deviceID; self.timestamp=timestamp
    }
}

public struct ProjectSnapshot: Codable, Equatable, Sendable {
    public let revision: ProjectRevision
    public let project: MusicProject

    public init(revision: ProjectRevision, project: MusicProject) {
        self.revision=revision; self.project=project
    }
}

public enum SyncDecision: Equatable, Sendable {
    case unchanged
    case acceptRemote
    case localAhead
    case conflict
}

public enum SyncResolver {
    public static func decide(local: ProjectRevision, remote: ProjectRevision) -> SyncDecision {
        guard local.projectID == remote.projectID else { return .conflict }
        if local.revision == remote.revision { return .unchanged }
        if local.revision < remote.revision { return .acceptRemote }
        return .localAhead
    }
}
