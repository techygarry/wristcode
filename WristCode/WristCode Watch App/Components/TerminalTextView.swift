import SwiftUI

// MARK: - Terminal Text View

/// Renders a TerminalMessage with appropriate prefix coloring and formatting.
struct TerminalTextView: View {
    let message: TerminalMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Prefix
            Text(message.type.prefix)
                .font(TerminalTheme.monoFont)
                .foregroundColor(message.type.color)

            // Content
            contentView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentView: some View {
        switch message.type {
        case .cost(let input, let output, let cost):
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: "$%.4f", cost))
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                Text("\(input)in / \(output)out")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim.opacity(0.6))
            }

        case .toolUse(let name):
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.cyan)
                    .bold()
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim)
                        .lineLimit(3)
                }
            }

        case .summary:
            Text(message.content)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.yellow)
                .italic()

        default:
            Text(message.content)
                .font(TerminalTheme.monoFont)
                .foregroundColor(message.type.color)
        }
    }
}
