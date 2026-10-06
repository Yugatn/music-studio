import SwiftUI

struct AIConnectionSettingsView: View {
    @ObservedObject var orchestrator: AIAgentOrchestrator
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AIConnectionConfig

    init(orchestrator: AIAgentOrchestrator) {
        self.orchestrator = orchestrator
        _draft = State(initialValue: orchestrator.connectionConfig)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect AI")
                .font(.title2.weight(.semibold))

            Text("Enable an external model (OpenAI-compatible chat API or custom agent). Settings stay on this Mac only.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Toggle("Enable remote AI", isOn: $draft.enabled)

            TextField("Display name", text: $draft.displayName)
            TextField("Base URL", text: $draft.baseURL)
                .textFieldStyle(.roundedBorder)
            SecureField("API key", text: $draft.apiKey)
                .textFieldStyle(.roundedBorder)
            TextField("Model", text: $draft.model)
                .textFieldStyle(.roundedBorder)
            TextField("Compose path", text: $draft.composePath)
                .textFieldStyle(.roundedBorder)

            Text("Example: Base URL https://api.openai.com/v1 · Path /chat/completions")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save & connect") {
                    orchestrator.applyConnection(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
