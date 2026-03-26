import SwiftUI

// MARK: - Diff Line View

/// Renders a single diff line with line number, +/- prefix, and colored text/background.
struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Line number
            Text("\(line.number)")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim.opacity(0.5))
                .frame(width: 18, alignment: .trailing)

            // +/- prefix
            Text(line.type.prefix)
                .font(TerminalTheme.monoFont)
                .foregroundColor(line.type.color)
                .frame(width: 8, alignment: .center)

            // Content
            Text(line.content)
                .font(TerminalTheme.monoFont)
                .foregroundColor(line.type.color)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 0)
        .background(line.type.backgroundColor)
    }
}
