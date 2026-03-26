# WristCode — Session 7: Terminal View + Voice Engine

## Context
Sessions 5-6 created the app foundation, connection services, and browser screens. Now build the main terminal interaction screen — the core experience.

## Task

### Views/TerminalView.swift
The heart of WristCode. Replicates Claude Code terminal output:

**Terminal Output Area** (ScrollView with ScrollViewReader):
- Auto-scrolls to bottom on new messages
- Messages rendered as raw terminal lines (NO chat bubbles):
  - User prompts: "❯ " prefix in dimmed + white text
  - Claude text: light gray (#E0E0E0), streams character-by-character
  - Tool use: "⚡ {toolName}" in blue (#58A6FF) + file path in cyan (#79C0FF)
  - Tool result: indented block with dark bg (#1C2128) + blue left border
  - Errors: red text (#E74C3C)
  - Success: green text (#2ECC71)
  - Cost: dimmed right-aligned "↑ 1.2k ↓ 847 tokens · $0.003"
  - Summary: orange bordered card with Haiku summary text
- Streaming animation: characters appear sequentially (25ms interval, configurable)
- Orange blinking cursor "▊" during streaming
- Digital Crown scrolls through history
- Scroll up pauses auto-scroll, tap bottom to resume

**Quick Actions** (horizontal ScrollView, above input):
- Pill-shaped buttons: "Status?" "Continue" "Fix it" "Show diff" "Commit"
- Dark bg, subtle border, dimmed text
- Tap sends the text as a prompt

**Input Bar** (bottom, always visible):
- Left: Orange circular mic button (22pt, with glow shadow) — tap to start voice
- Center: Dark text field "Type or speak..." — tap opens watch keyboard
- Right: Keyboard emoji icon
- Send on: tap send button, or auto-send after voice silence

**SSE Integration**:
- On appear: call bridgeConnection.connectStream(sessionId)
- Parse incoming SSE events into TerminalMessage objects
- Handle approval_request → navigate to DiffView
- Handle status changes → update header dot color
- Handle disconnect → show orange "Reconnecting..." banner at top

**Header**:
- PixelMascot (8pt) + project name in orange | StatusDot + model name dimmed
- Minimal — maximize terminal real estate

### Components/QuickActionPill.swift
```swift
struct QuickActionPill: View {
    let text: String
    let action: () -> Void
    // Dark bg, 1px border, dimmed text, rounded pill shape
    // Tap highlight: orange border flash
}
```

### Components/TerminalTextView.swift
```swift
struct TerminalTextView: View {
    let message: TerminalMessage
    // Renders a single terminal line with appropriate color/prefix
    // Monospace font, no padding (raw terminal look)
    // Long lines: horizontal scroll (not wrap, like a real terminal)
}
```

### Views/CommandPaletteView.swift
Slash commands overlay:
- Triggered by swipe-up gesture on terminal view
- Sheet with dark bg listing commands:
  - /help — Show available commands
  - /clear — Clear terminal history
  - /compact — Compact conversation context
  - /status — Show session status
  - /cost — Show token usage and cost
- Each command in a row: orange "/" + command name + dimmed description
- Tap sends command via POST /sessions/:id/command

### Services/VoiceEngine.swift
```swift
class VoiceEngine: ObservableObject {
    @Published var isListening: Bool = false
    @Published var transcription: String = ""
    @Published var isSpeaking: Bool = false

    // Speech Recognition (SFSpeechRecognizer)
    func startListening()   // On-device recognition
    func stopListening()
    var autoSendDelay: TimeInterval = 1.5  // seconds of silence before auto-send

    // TTS (AVSpeechSynthesizer)
    func speak(_ text: String)  // Speak Haiku TTS summary
    func stopSpeaking()

    // Mode
    enum IOMode { case voiceVoice, voiceText, textVoice, textText }
    var mode: IOMode = .voiceText

    // Permissions
    func requestPermissions() async -> Bool
}
```

### Services/HapticManager.swift
```swift
struct HapticManager {
    static func success()      // Task complete — WKInterfaceDevice .success
    static func approval()     // Approval needed — .notification
    static func click()        // Button tap — .click
    static func reject()       // Rejection — .failure
    static func error()        // Error — .retry
}
```

## Critical UX Details
- Terminal text should feel ALIVE — streaming characters, blinking cursor, subtle glow on active elements
- Transition to DiffView should be automatic when approval_request arrives (with haptic)
- Voice button glows brighter when listening (animate shadow radius)
- Keep terminal view state alive when navigating to DiffView and back
- Memory efficient: only keep last 200 messages in view, older messages paged from cache
