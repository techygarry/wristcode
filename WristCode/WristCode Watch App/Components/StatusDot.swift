import SwiftUI

// MARK: - Status Dot

/// A small colored circle with a glow effect indicating connection or session status.
struct StatusDot: View {
    let color: Color
    var size: CGFloat = 6
    var pulse: Bool = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.6), radius: size * 0.5)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: pulse ? 2 : 0)
                    .frame(width: size + 4, height: size + 4)
                    .opacity(pulse ? 1 : 0)
                    .animation(
                        pulse
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse
                    )
            )
    }
}
