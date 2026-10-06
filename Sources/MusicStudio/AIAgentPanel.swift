import SwiftUI

/// Inspector section for connecting agents and the rework-after-subject loop.
struct AIAgentPanel: View {
    @ObservedObject var orchestrator: AIAgentOrchestrator
    let project: MusicProject
    let currentPattern: Pattern?
    let prompt: String
    let isBusy: Bool
    var onGenerate: () -> Void
    var onRework: () -> Void
    var onContinue: () -> Void
    var onAccept: () -> Void
    var onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI AGENT").font(.caption).foregroundStyle(.secondary)

            Picker("Agent", selection: activeAgentBinding) {
                ForEach(orchestrator.availableAgents) { agent in
                    Text(agent.displayName).tag(agent.id)
                }
            }

            if let agent = orchestrator.availableAgents.first(where: { $0.id == orchestrator.session.activeAgentID }) {
                Text(agent.summary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Generate") { onGenerate() }
                    .disabled(isBusy)
                    .help("Independent generation from prompt")
                Button("Rework after edits") { onRework() }
                    .disabled(isBusy || (currentPattern?.notes.isEmpty ?? true))
                    .help("Agent reworks the current subject-edited melody")
            }
            Button("Continue independently") { onContinue() }
                .disabled(isBusy)
                .help("Agent continues from last subject edit or last accepted candidate")

            if orchestrator.session.pendingCandidate != nil {
                Divider()
                Text("CANDIDATE").font(.caption2).foregroundStyle(.secondary)
                if let explanation = orchestrator.session.pendingExplanation {
                    Text(explanation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(orchestrator.session.pendingCandidate?.notes.count ?? 0) notes staged")
                    .font(.caption2)
                HStack {
                    Button("Accept") { onAccept() }
                    Button("Reject", role: .destructive) { onReject() }
                }
            }

            if let err = orchestrator.lastError {
                Text(err).font(.caption2).foregroundStyle(.red)
            }

            if !orchestrator.session.turns.isEmpty {
                Divider()
                Text("SESSION").font(.caption2).foregroundStyle(.secondary)
                ForEach(orchestrator.session.turns.suffix(6).reversed()) { turn in
                    Text(turnLabel(turn))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text("After you edit notes, use Rework — the agent must start from your version.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var activeAgentBinding: Binding<String> {
        Binding(
            get: { orchestrator.session.activeAgentID },
            set: { orchestrator.selectAgent(id: $0) }
        )
    }

    private func turnLabel(_ turn: AIAgentTurn) -> String {
        let kind: String
        switch turn.kind {
        case .agentGenerate: kind = "Agent generate"
        case .subjectEdit: kind = "Subject edit"
        case .agentReworkAfterSubject: kind = "Agent rework"
        case .agentIndependentContinue: kind = "Agent continue"
        case .subjectAccept: kind = "Accepted"
        case .subjectReject: kind = "Rejected"
        }
        let notes = turn.noteCount.map { " · \($0)n" } ?? ""
        return "\(kind)\(notes)"
    }
}
