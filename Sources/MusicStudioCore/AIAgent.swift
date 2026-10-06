import Foundation

/// Identity of a pluggable AI music agent.
public struct AIAgentDescriptor: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var displayName: String
    public var summary: String
    public var supportsIndependentWork: Bool
    public var supportsReworkAfterSubject: Bool

    public init(
        id: String,
        displayName: String,
        summary: String,
        supportsIndependentWork: Bool = true,
        supportsReworkAfterSubject: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.summary = summary
        self.supportsIndependentWork = supportsIndependentWork
        self.supportsReworkAfterSubject = supportsReworkAfterSubject
    }
}

/// Snapshot of subject (human) edits that an agent must respect as source of truth.
public struct SubjectEditSnapshot: Codable, Sendable {
    public let pattern: Pattern
    public let projectID: UUID?
    public let noteCount: Int
    public let recordedAt: Date
    public let label: String

    public init(
        pattern: Pattern,
        projectID: UUID? = nil,
        recordedAt: Date = Date(),
        label: String = "subject-edit"
    ) {
        self.pattern = pattern
        self.projectID = projectID
        self.noteCount = pattern.notes.count
        self.recordedAt = recordedAt
        self.label = label
    }
}

/// One turn in the human ↔ agent loop.
public enum AIAgentTurnKind: String, Codable, Sendable {
    case agentGenerate
    case subjectEdit
    case agentReworkAfterSubject
    case agentIndependentContinue
    case subjectAccept
    case subjectReject
}

public struct AIAgentTurn: Codable, Identifiable, Sendable {
    public let id: UUID
    public let kind: AIAgentTurnKind
    public let agentID: String?
    public let at: Date
    public let noteCount: Int?
    public let explanation: String?

    public init(
        id: UUID = UUID(),
        kind: AIAgentTurnKind,
        agentID: String? = nil,
        at: Date = Date(),
        noteCount: Int? = nil,
        explanation: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.agentID = agentID
        self.at = at
        self.noteCount = noteCount
        self.explanation = explanation
    }
}

/// Session state: agents may work independently, but after subject edits must rework from the edited pattern.
public struct AIAgentSession: Codable, Sendable {
    public var activeAgentID: String
    public var turns: [AIAgentTurn]
    public var lastSubjectSnapshot: SubjectEditSnapshot?
    public var lastAgentPattern: Pattern?
    public var pendingCandidate: Pattern?
    public var pendingExplanation: String?

    public init(activeAgentID: String) {
        self.activeAgentID = activeAgentID
        self.turns = []
        self.lastSubjectSnapshot = nil
        self.lastAgentPattern = nil
        self.pendingCandidate = nil
        self.pendingExplanation = nil
    }

    public mutating func recordSubjectEdit(_ snapshot: SubjectEditSnapshot) {
        lastSubjectSnapshot = snapshot
        turns.append(AIAgentTurn(kind: .subjectEdit, noteCount: snapshot.noteCount, explanation: snapshot.label))
        // Pending AI result is invalidated when the subject changes the source.
        pendingCandidate = nil
        pendingExplanation = nil
    }

    public mutating func stageCandidate(_ pattern: Pattern, agentID: String, kind: AIAgentTurnKind, explanation: String) {
        pendingCandidate = pattern
        pendingExplanation = explanation
        turns.append(AIAgentTurn(kind: kind, agentID: agentID, noteCount: pattern.notes.count, explanation: explanation))
    }

    public mutating func acceptPending() -> Pattern? {
        guard let candidate = pendingCandidate else { return nil }
        lastAgentPattern = candidate
        turns.append(AIAgentTurn(kind: .subjectAccept, agentID: activeAgentID, noteCount: candidate.notes.count))
        pendingCandidate = nil
        pendingExplanation = nil
        return candidate
    }

    public mutating func rejectPending() {
        turns.append(AIAgentTurn(kind: .subjectReject, agentID: activeAgentID))
        pendingCandidate = nil
        pendingExplanation = nil
    }

    /// Source pattern for rework: prefer last subject edit, else last accepted agent, else nil.
    public var preferredSourcePattern: Pattern? {
        lastSubjectSnapshot?.pattern ?? lastAgentPattern
    }
}

/// Pluggable agent that can generate and, critically, rework after subject edits.
public protocol AIMusicAgent: Sendable {
    var descriptor: AIAgentDescriptor { get }
    func compose(_ context: AICompositionContext) async throws -> AICompositionResult
}

/// Registry of connectable agents (local demo, future remote HTTP, etc.).
public final class AIAgentRegistry: @unchecked Sendable {
    private var agents: [String: AIMusicAgent] = [:]

    public init() {}

    public func register(_ agent: AIMusicAgent) {
        agents[agent.descriptor.id] = agent
    }

    public func unregister(id: String) {
        agents.removeValue(forKey: id)
    }

    public func agent(id: String) -> AIMusicAgent? {
        agents[id]
    }

    public var allDescriptors: [AIAgentDescriptor] {
        agents.values.map(\.descriptor).sorted { $0.displayName < $1.displayName }
    }
}
