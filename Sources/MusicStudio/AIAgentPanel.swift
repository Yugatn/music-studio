import SwiftUI

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

    @State private var showConnection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI AGENT").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Connect AI…") { showConnection = true }
                    .font(.caption)
            }

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

            if orchestrator.connectionConfig.isReady {
                Text("Remote: on · \(orchestrator.connectionConfig.model)")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                Text("Remote: off (local agents only)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Generate") { onGenerate() }
                    .disabled(isBusy)
                Button("Rework after edits") { onRework() }
                    .disabled(isBusy || (currentPattern?.notes.isEmpty ?? true))
            }
            Button("Continue independently") { onContinue() }
                .disabled(isBusy)

            if orchestrator.session.pendingCandidate != nil {
                Divider()
                Text("CANDIDATE").font(.caption2).foregroundStyle(.secondary)
                if let explanation = orchestrator.session.pendingExplanation {
                    Text(explanation).font(.caption2).foregroundStyle(.secondary)
                }
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
                ForEach(orchestrator.session.turns.suffix(5).reversed()) { turn in
                    Text(turnLabel(turn))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .sheet(isPresented: $showConnection) {
            AIConnectionSettingsView(orchestrator: orchestrator)
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
