import Foundation
import MusicStudioCore

// MARK: - Demo agents (local, no network)

/// Default melodic agent: generate from prompt or continue from edited notes.
struct LocalMelodyAgent: AIMusicAgent {
    let descriptor = AIAgentDescriptor(
        id: "local.melody",
        displayName: "Local Melody",
        summary: "Deterministic local generator; reworks from subject-edited pattern."
    )
    private let engine = DemoAIComposer()

    func compose(_ context: AICompositionContext) async throws -> AICompositionResult {
        let request = MelodyRequest(
            prompt: context.request.prompt,
            bpm: context.request.bpm,
            key: context.request.key,
            scale: context.request.scale,
            bars: context.request.bars
        )
        switch context.mode {
        case .generate:
            let pattern = try await engine.generateMelody(request)
            return AICompositionResult(
                pattern: pattern,
                mode: .generate,
                sourceRevision: context.request.sourceRevision,
                explanation: "Generated new melody from prompt (local agent)."
            )
        case .continueFromEdited, .transformEdited, .regenerateVariation:
            guard let source = context.sourcePattern, !source.notes.isEmpty else {
                let pattern = try await engine.generateMelody(request)
                return AICompositionResult(
                    pattern: pattern,
                    mode: context.mode,
                    sourceRevision: context.request.sourceRevision,
                    explanation: "No subject notes found; generated fresh candidate."
                )
            }
            let instruction = context.request.instruction ?? context.request.prompt
            let revised = try await engine.reworkAfterSubject(
                source,
                request: request,
                instruction: instruction
            )
            return AICompositionResult(
                pattern: revised,
                mode: context.mode,
                sourceRevision: context.request.sourceRevision,
                explanation: "Reworked after subject edits: kept structure, applied ‘\(instruction)’ (local)."
            )
        }
    }
}

/// Variation-focused agent: stronger changes, still based on subject material.
struct LocalVariationAgent: AIMusicAgent {
    let descriptor = AIAgentDescriptor(
        id: "local.variation",
        displayName: "Local Variation",
        summary: "Stronger variations of the current subject melody."
    )
    private let engine = DemoAIComposer()

    func compose(_ context: AICompositionContext) async throws -> AICompositionResult {
        let request = MelodyRequest(
            prompt: context.request.prompt,
            bpm: context.request.bpm,
            key: context.request.key,
            scale: context.request.scale,
            bars: context.request.bars
        )
        if let source = context.sourcePattern, !source.notes.isEmpty {
            let revised = try await engine.reworkAfterSubject(
                source,
                request: request,
                instruction: context.request.instruction ?? "variation denser expressive",
                aggressive: true
            )
            return AICompositionResult(
                pattern: revised,
                mode: .regenerateVariation,
                sourceRevision: context.request.sourceRevision,
                explanation: "Variation agent: denser/expressive rework of subject melody."
            )
        }
        let pattern = try await engine.generateMelody(request)
        return AICompositionResult(
            pattern: pattern,
            mode: .generate,
            sourceRevision: nil,
            explanation: "Variation agent: no source; generated new material."
        )
    }
}

// MARK: - Orchestrator

@MainActor
final class AIAgentOrchestrator: ObservableObject {
    @Published private(set) var session: AIAgentSession
    @Published private(set) var availableAgents: [AIAgentDescriptor] = []
    @Published var lastError: String?

    private let registry = AIAgentRegistry()

    init() {
        let melody = LocalMelodyAgent()
        let variation = LocalVariationAgent()
        registry.register(melody)
        registry.register(variation)
        session = AIAgentSession(activeAgentID: melody.descriptor.id)
        availableAgents = registry.allDescriptors
    }

    func selectAgent(id: String) {
        guard registry.agent(id: id) != nil else { return }
        session.activeAgentID = id
    }

    /// Call after the subject mutates notes (manual piano-roll edit).
    func noteSubjectEdit(pattern: Pattern, projectID: UUID?) {
        session.recordSubjectEdit(SubjectEditSnapshot(pattern: pattern, projectID: projectID))
    }

    /// Independent generation (no required subject source).
    func generateIndependent(
        project: MusicProject,
        prompt: String,
        bars: Int = 2
    ) async -> AICompositionResult? {
        await run(
            mode: .generate,
            project: project,
            prompt: prompt,
            instruction: prompt,
            sourcePattern: nil,
            bars: bars,
            turnKind: .agentGenerate
        )
    }

    /// Rework using the current pattern after subject edits — core collaborative loop.
    func reworkAfterSubject(
        project: MusicProject,
        currentPattern: Pattern,
        instruction: String
    ) async -> AICompositionResult? {
        session.recordSubjectEdit(SubjectEditSnapshot(pattern: currentPattern, projectID: project.id))
        return await run(
            mode: .transformEdited,
            project: project,
            prompt: instruction,
            instruction: instruction,
            sourcePattern: currentPattern,
            bars: max(1, Int(currentPattern.lengthBeats / 4)),
            turnKind: .agentReworkAfterSubject
        )
    }

    /// Agent continues independently from last accepted or last subject snapshot.
    func continueIndependent(project: MusicProject, prompt: String) async -> AICompositionResult? {
        let source = session.preferredSourcePattern ?? project.tracks.first?.pattern
        return await run(
            mode: .continueFromEdited,
            project: project,
            prompt: prompt,
            instruction: prompt,
            sourcePattern: source,
            bars: max(1, Int((source?.lengthBeats ?? 8) / 4)),
            turnKind: .agentIndependentContinue
        )
    }

    func acceptPending() -> Pattern? {
        session.acceptPending()
    }

    func rejectPending() {
        session.rejectPending()
    }

    private func run(
        mode: AICompositionMode,
        project: MusicProject,
        prompt: String,
        instruction: String,
        sourcePattern: Pattern?,
        bars: Int,
        turnKind: AIAgentTurnKind
    ) async -> AICompositionResult? {
        lastError = nil
        guard let agent = registry.agent(id: session.activeAgentID) else {
            lastError = "Agent not registered: \(session.activeAgentID)"
            return nil
        }
        let request = AICompositionRequest(
            prompt: prompt,
            bpm: project.bpm,
            key: project.key,
            scale: project.scale,
            bars: bars,
            sourceProjectID: project.id,
            instruction: instruction
        )
        let context = AICompositionContext(
            mode: mode,
            sourceProject: project,
            sourcePattern: sourcePattern,
            request: request
        )
        do {
            let result = try await agent.compose(context)
            session.stageCandidate(
                result.pattern,
                agentID: agent.descriptor.id,
                kind: turnKind,
                explanation: result.explanation
            )
            return result
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}
