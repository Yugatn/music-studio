import Foundation

public struct CompositionRevision: Codable, Identifiable, Sendable {
    public let id: UUID
    public let revision: Int64
    public let project: MusicProject
    public let parentRevision: Int64?
    public let createdAt: Date
    public let label: String

    public init(id: UUID = UUID(), revision: Int64, project: MusicProject, parentRevision: Int64?, createdAt: Date = Date(), label: String) {
        self.id=id; self.revision=revision; self.project=project; self.parentRevision=parentRevision; self.createdAt=createdAt; self.label=label
    }
}

public struct CompositionRevisionGraph: Sendable {
    private var revisions: [CompositionRevision] = []

    public init() {}

    public var all: [CompositionRevision] { revisions }

    public mutating func append(project: MusicProject, label: String, parentRevision: Int64? = nil) -> CompositionRevision {
        let next = (revisions.last?.revision ?? 0) + 1
        let revision = CompositionRevision(revision: next, project: project, parentRevision: parentRevision ?? revisions.last?.revision, label: label)
        revisions.append(revision)
        return revision
    }

    public func project(at revision: Int64) -> MusicProject? {
        revisions.first(where: { $0.revision == revision })?.project
    }

    public func latest() -> CompositionRevision? { revisions.last }
}
