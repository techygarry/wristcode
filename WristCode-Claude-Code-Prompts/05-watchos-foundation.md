# WristCode — Session 5: watchOS App Foundation + Theme

## Context
Bridge server is complete (Sessions 1-4). Now build the watchOS app with SwiftUI. This session creates the project structure, terminal theme system, and core navigation.

## Prerequisites
- Xcode 15+ installed
- watchOS 10 SDK target
- This is a watchOS-only app with a minimal iOS companion

## Task
Create the Xcode project "WristCode" with a watchOS target.

### Theme/TerminalTheme.swift
Complete design system — the CORE of the app's identity:

```swift
struct TerminalTheme {
    // Backgrounds
    static let bg = Color(hex: "0F1117")
    static let bgCard = Color(hex: "161B22")
    static let inputBg = Color(hex: "1C2128")

    // Primary
    static let orange = Color(hex: "E8732A")       // Headers, borders, mascot, accent
    static let text = Color(hex: "E0E0E0")          // Primary terminal text
    static let textDim = Color(hex: "8B949E")        // Secondary/metadata text

    // Status
    static let green = Color(hex: "2ECC71")          // Success, connected, approve
    static let red = Color(hex: "E74C3C")            // Error, reject, delete
    static let yellow = Color(hex: "F39C12")         // Warning, pending approval

    // Code
    static let blue = Color(hex: "58A6FF")           // Tool usage
    static let cyan = Color(hex: "79C0FF")           // File paths

    // Borders
    static let border = Color(hex: "2D333B")         // Default border
    static let borderActive = Color(hex: "E8732A")   // Active/selected border

    // Typography
    static let monoFont = Font.system(.caption2, design: .monospaced)
    static let monoBody = Font.system(.caption, design: .monospaced)
    static let monoHeader = Font.system(.footnote, design: .monospaced).bold()
    static let monoTitle = Font.system(.body, design: .monospaced).bold()

    // Corner radius
    static let cornerRadius: CGFloat = 4  // Terminal aesthetic, NOT rounded iOS
}

extension Color {
    init(hex: String) { /* hex string to Color */ }
}
```

### Components/PixelMascot.swift
Orange pixel robot — the Claude Code mascot rendered as SwiftUI shapes:
- 7x7 pixel grid using Rectangle shapes
- Orange body with dark "eye" and "mouth" cutouts
- Scalable via size parameter
- Matches the Claude Code CLI mascot exactly

### Components/StatusDot.swift
```swift
struct StatusDot: View {
    let color: Color
    var size: CGFloat = 6
    // Circular dot with subtle glow shadow
}
```

### Models/BridgeConfig.swift
```swift
struct BridgeConfig: Codable {
    var host: String = ""
    var port: Int = 3847
    var tailscaleIP: String = ""
    var pairingCode: String = ""
    var jwtToken: String?
    var isPaired: Bool { jwtToken != nil }
}
```

### Models/Session.swift
```swift
struct Session: Identifiable, Codable {
    let id: String
    let cwd: String
    let model: String
    var status: SessionStatus
    var lastActive: Date
    var projectName: String { /* extract last path component from cwd */ }
}

enum SessionStatus: String, Codable {
    case running, waiting, idle, error
    var color: Color { /* green/yellow/gray/red */ }
    var label: String { /* Running/Waiting/Idle/Error */ }
}
```

### Models/TerminalMessage.swift
```swift
struct TerminalMessage: Identifiable {
    let id: UUID
    let type: MessageType
    let content: String
    let timestamp: Date

    enum MessageType {
        case userPrompt       // White text with "❯" prefix
        case assistantText    // Light gray
        case toolUse(name: String)  // Blue with tool name
        case toolResult       // Dimmed
        case filePath         // Cyan
        case error            // Red
        case success          // Green
        case cost(input: Int, output: Int, cost: Double)
        case summary(String)

        var color: Color { /* map to TerminalTheme colors */ }
    }
}
```

### ContentView.swift
```swift
NavigationStack {
    WelcomeView()
        .background(TerminalTheme.bg)
}
.environment(\.font, TerminalTheme.monoBody)
```

### WristCodeApp.swift
```swift
@main
struct WristCodeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
```

## Critical Rules
1. EVERYTHING uses monospace fonts — no San Francisco proportional
2. Background is ALWAYS #0F1117 — no system backgrounds
3. Corner radius MAX 4pt — this is a terminal, not iOS
4. No SF Symbols except where explicitly needed — use text characters
5. All text colors from TerminalTheme — no system colors
6. The app should feel like SSH into a terminal, not a native watch app
