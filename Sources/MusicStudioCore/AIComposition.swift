import Foundation

public struct AICompositionRequest: Codable, Sendable {
    public var prompt: String
    public var bpm: Double
    public var key: String
    public var scale: String
    public var bars: Int
    public var sourceProjectID: UUID?
    public var sourceRevision: Int64?
    public var instruction: String?

    public init(prompt: String, bpm: Double, key: String, scale: String, bars: Int = 4, sourceProjectID: UUID? = nil, sourceRevision: Int64? = nil, instruction: String? = nil) {
        self.prompt=prompt; self.bpm=bpm; self.key=key; self.scale=scale; self.bars=bars
        self.sourceProjectID=sourceProjectID; self.sourceRevision=sourceRevision; self.instruction=instruction
    }
}

public enum AICompositionMode: String, Codable, Sendable {
    case generate
    case continueFromEdited
    case transformEdited
    case regenerateVariation
}

public struct AICompositionContext: Codable, Sendable {
    public var mode: AICompositionMode
    public var sourceProject: MusicProject?
    public var sourcePattern: Pattern?
    public var request: AICompositionRequest

    public init(mode: AICompositionMode, sourceProject: MusicProject? = nil, sourcePattern: Pattern? = nil, request: AICompositionRequest) {
        self.mode=mode; self.sourceProject=sourceProject; self.sourcePattern=sourcePattern; self.request=request
    }
}

public struct AICompositionResult: Codable, Sendable {
    public let pattern: Pattern
    public let mode: AICompositionMode
    public let sourceRevision: Int64?
    public let explanation: String

    public init(pattern: Pattern, mode: AICompositionMode, sourceRevision: Int64?, explanation: String) {
        self.pattern=pattern; self.mode=mode; self.sourceRevision=sourceRevision; self.explanation=explanation
    }
}

public protocol AICompositionEngine: Sendable {
    func compose(_ context: AICompositionContext) async throws -> AICompositionResult
}
