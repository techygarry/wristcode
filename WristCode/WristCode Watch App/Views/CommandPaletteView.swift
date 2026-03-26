import SwiftUI

// MARK: - Command Palette View

struct CommandPaletteView: View {
    let sessionId: String

    @EnvironmentObject var bridge: BridgeConnection
    @Environment(\.dismiss) private var dismiss

    private struct SlashCommand: Identifiable {
        let id = UUID()
        let name: String
        let description: String
    }

    private let commands: [SlashCommand] = [
        SlashCommand(name: "help", description: "Show available commands"),
        SlashCommand(name: "clear", description: "Clear terminal output"),
        SlashCommand(name: "compact", description: "Compact conversation history"),
        SlashCommand(name: "status", description: "Show session status"),
        SlashCommand(name: "cost", description: "Show token usage & cost"),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 1) {
                // Header
                HStack {
                    Text("Commands")
                        .font(TerminalTheme.monoHeader)
                        .foregroundColor(TerminalTheme.text)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("\u{00D7}")
                            .font(TerminalTheme.monoBody)
                            .foregroundColor(TerminalTheme.textDim)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 2)

                // Command list
                ForEach(commands) { command in
                    Button {
                        HapticManager.click()
                        let cmd = command.name
                        Task {
                            _ = try? await bridge.sendCommand(
                                sessionId: sessionId,
                                command: "/\(cmd)"
                            )
                        }
                        dismiss()
                    } label: {
                        commandRow(command)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 3)
        }
        .background(TerminalTheme.bg)
    }

    private func commandRow(_ command: SlashCommand) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text("/")
                .font(TerminalTheme.monoBody)
                .foregroundColor(TerminalTheme.orange)
            Text(command.name)
                .font(TerminalTheme.monoBody)
                .foregroundColor(TerminalTheme.text)

            Spacer()

            Text(command.description)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .background(TerminalTheme.bgCard)
        .cornerRadius(TerminalTheme.cornerRadius)
    }
}
