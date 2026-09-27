import Foundation

public struct RevisionEnvelope: Codable, Equatable, Sendable {
    public let operationID: UUID
    public let projectID: UUID
    public let revision: UInt64
    public let parentRevision: UInt64?
    public let deviceID: UUID
    public let createdAt: Date
    public let payloadDigest: String

    public init(operationID: UUID = UUID(), projectID: UUID, revision: UInt64, parentRevision: UInt64?, deviceID: UUID, createdAt: Date = Date(), payloadDigest: String) {
        self.operationID=operationID; self.projectID=projectID; self.revision=revision
        self.parentRevision=parentRevision; self.deviceID=deviceID; self.createdAt=createdAt; self.payloadDigest=payloadDigest
    }
}

public enum RevisionValidationError: Error, Equatable {
    case invalidRevision
    case parentMismatch
    case projectMismatch
    case duplicateOperation
    case digestMismatch
}

public struct RevisionSecurityState: Sendable {
    public private(set) var projectID: UUID
    public private(set) var highestRevision: UInt64
    private var acceptedOperations: Set<UUID>

    public init(projectID: UUID, highestRevision: UInt64 = 0) {
        self.projectID=projectID; self.highestRevision=highestRevision; self.acceptedOperations=[]
    }

    public mutating func validate(_ envelope: RevisionEnvelope) throws {
        guard envelope.projectID == projectID else { throw RevisionValidationError.projectMismatch }
        guard envelope.revision > highestRevision else {
            if acceptedOperations.contains(envelope.operationID) { throw RevisionValidationError.duplicateOperation }
            throw RevisionValidationError.invalidRevision
        }
        if let parent = envelope.parentRevision, parent != highestRevision {
            throw RevisionValidationError.parentMismatch
        }
    }

    public mutating func accept(_ envelope: RevisionEnvelope) throws {
        try validate(envelope)
        acceptedOperations.insert(envelope.operationID)
        highestRevision=envelope.revision
    }
}
