import SwiftUI

// MARK: - Quick Action Pill

/// Pill-shaped button with dark background and subtle border.
struct QuickActionPill: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .background(TerminalTheme.bgCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(TerminalTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
