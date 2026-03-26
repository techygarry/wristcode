import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Terminal Theme

enum TerminalTheme {

    // MARK: Colors

    static let bg        = Color(hex: "0F1117")
    static let bgCard    = Color(hex: "161B22")
    static let inputBg   = Color(hex: "1C2128")
    static let orange    = Color(hex: "E8732A")
    static let text      = Color(hex: "E0E0E0")
    static let textDim   = Color(hex: "8B949E")
    static let green     = Color(hex: "2ECC71")
    static let red       = Color(hex: "E74C3C")
    static let yellow    = Color(hex: "F39C12")
    static let blue      = Color(hex: "58A6FF")
    static let cyan      = Color(hex: "79C0FF")
    static let border    = Color(hex: "2D333B")

    // MARK: Typography

    static let monoFont   = Font.system(size: 8.5, design: .monospaced)                     // Smallest – metadata, secondary
    static let monoBody   = Font.system(size: 9.5, design: .monospaced)                    // Body text
    static let monoHeader = Font.system(size: 11, weight: .bold, design: .monospaced)      // Section headers
    static let monoTitle  = Font.system(size: 12, weight: .bold, design: .monospaced)      // Main titles

    // MARK: Layout

    static let cornerRadius: CGFloat = 3
}
