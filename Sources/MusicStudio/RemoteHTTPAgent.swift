import Foundation
import MusicStudioCore

/// Connects to an external AI HTTP API and maps responses into Pattern candidates.
/// Falls back to local rework if the network call fails or returns unusable data.
struct RemoteHTTPAgent: AIMusicAgent {
    let config: AIConnectionConfig
    private let fallback = DemoAIComposer()

    var descriptor: AIAgentDescriptor {
        AIAgentDescriptor(
            id: "remote.http",
            displayName: config.displayName.isEmpty ? "Remote AI" : config.displayName,
            summary: "External AI via \(config.baseURL). Falls back to local engine on failure.",
            supportsIndependentWork: true,
            supportsReworkAfterSubject: true
        )
    }

    func compose(_ context: AICompositionContext) async throws -> AICompositionResult {
        let request = MelodyRequest(
            prompt: context.request.prompt,
            bpm: context.request.bpm,
            key: context.request.key,
            scale: context.request.scale,
            bars: context.request.bars
        )

        if config.isReady {
            if let remote = try? await callRemote(context: context) {
                return remote
            }
        }

        // Local fallback — still honors subject source when present
        switch context.mode {
        case .generate:
            let pattern = try await fallback.generateMelody(request)
            return AICompositionResult(
                pattern: pattern,
                mode: .generate,
                sourceRevision: context.request.sourceRevision,
                explanation: "Remote unavailable or disabled; local generate."
            )
        case .continueFromEdited, .transformEdited, .regenerateVariation:
            let source = context.sourcePattern
            if let source, !source.notes.isEmpty {
                let revised = try await fallback.reworkAfterSubject(
                    source,
                    request: request,
                    instruction: context.request.instruction ?? context.request.prompt
                )
                return AICompositionResult(
                    pattern: revised,
                    mode: context.mode,
                    sourceRevision: context.request.sourceRevision,
                    explanation: "Remote unavailable; local rework after subject."
                )
            }
            let pattern = try await fallback.generateMelody(request)
            return AICompositionResult(
                pattern: pattern,
                mode: context.mode,
                sourceRevision: nil,
                explanation: "Remote unavailable; local generate (no subject notes)."
            )
        }
    }

    private func callRemote(context: AICompositionContext) async throws -> AICompositionResult? {
        let base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = config.composePath.hasPrefix("/") ? config.composePath : "/" + config.composePath
        guard let url = URL(string: base + path) else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty {
            req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        req.timeoutInterval = config.timeoutSeconds

        let system = """
        You are a music composition agent for Music Studio.
        Return ONLY valid JSON with this shape:
        {"notes":[{"pitch":60,"startBeat":0.0,"durationBeats":0.5,"velocity":96}],"lengthBeats":8.0,"explanation":"..."}
        pitch is MIDI 24-108. Prefer the subject's existing notes when mode is transform/continue.
        """

        var userParts: [String] = [
            "mode: \(context.mode.rawValue)",
            "prompt: \(context.request.prompt)",
            "bpm: \(context.request.bpm)",
            "key: \(context.request.key)",
            "scale: \(context.request.scale)",
            "bars: \(context.request.bars)"
        ]
        if let instruction = context.request.instruction {
            userParts.append("instruction: \(instruction)")
        }
        if let source = context.sourcePattern {
            let summary = source.notes.prefix(64).map {
                "(\($0.pitch),\($0.startBeat),\($0.durationBeats),\($0.velocity))"
            }.joined(separator: ",")
            userParts.append("subject_notes: [\(summary)]")
            userParts.append("subject_lengthBeats: \(source.lengthBeats)")
        }

        let body: [String: Any] = [
            "model": config.model,
            "temperature": 0.7,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": userParts.joined(separator: "\n")]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard data.count <= 2_000_000,
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            return nil
        }

        // OpenAI-style chat completion or raw JSON pattern
        if let pattern = parseOpenAIChat(data: data) ?? parseDirectPattern(data: data) {
            return AICompositionResult(
                pattern: pattern,
                mode: context.mode,
                sourceRevision: context.request.sourceRevision,
                explanation: pattern.name.isEmpty ? "Remote AI candidate" : pattern.name
            )
        }
        return nil
    }

    private func parseOpenAIChat(data: Data) -> Pattern? {
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
            }
            let choices: [Choice]?
        }
        guard let chat = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = chat.choices?.first?.message.content
        else { return nil }
        let jsonSlice = extractJSONObject(from: content) ?? content
        guard let jsonData = jsonSlice.data(using: .utf8) else { return nil }
        return parseDirectPattern(data: jsonData)
    }

    private func parseDirectPattern(data: Data) -> Pattern? {
        struct NoteDTO: Decodable {
            let pitch: Int
            let startBeat: Double
            let durationBeats: Double
            let velocity: Int?
        }
        struct PatternDTO: Decodable {
            let notes: [NoteDTO]
            let lengthBeats: Double?
            let explanation: String?
        }
        guard let dto = try? JSONDecoder().decode(PatternDTO.self, from: data),
              !dto.notes.isEmpty,
              dto.notes.count <= 512 else {
            return nil
        }
        let notes = dto.notes.compactMap { raw -> NoteEvent? in
            guard raw.startBeat.isFinite,
                  raw.durationBeats.isFinite,
                  raw.startBeat >= 0,
                  raw.durationBeats > 0 else { return nil }
            return NoteEvent(
                pitch: max(24, min(108, raw.pitch)),
                startBeat: raw.startBeat,
                durationBeats: min(32, max(0.25, raw.durationBeats)),
                velocity: max(1, min(127, raw.velocity ?? 96))
            )
        }
        guard !notes.isEmpty else { return nil }
        let length = dto.lengthBeats ?? max(8, notes.map { $0.startBeat + $0.durationBeats }.max() ?? 8)
        return Pattern(name: dto.explanation ?? "Remote AI", lengthBeats: length, notes: notes)
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}")
        else { return nil }
        return String(text[start...end])
    }
}
