# WristCode — Session 8: Diff Viewer + Complications + Polish

## Context
Sessions 5-7 built the watchOS app with terminal view and voice. This final session adds the diff viewer, watch face complications, settings, and polish.

## Task

### Views/DiffView.swift
File change review screen — shown when Claude proposes edits:

Layout:
1. **Header**: "Review Changes" orange bold | Yellow badge "N files" if multiple
2. **AI Summary card**: Dark card with "🤖 Summary" orange label + plain English description from Haiku
3. **File header**: Dark bg (#1C2128), file path in cyan, "+N, -N" change count
4. **Diff lines** (ScrollView):
   - Added lines: green text, green left border, subtle green bg tint
   - Removed lines: red text, red left border, subtle red bg tint
   - Context lines: dimmed gray, transparent bg
   - Line numbers in dimmed text (right-aligned, fixed width)
   - +/- prefix before each line
   - Horizontal scroll for long lines (monospace, no wrapping)
5. **Page dots**: If multiple files, show dot indicators + swipe between files (TabView)
6. **Action buttons**: Two large buttons side by side:
   - Left: Red outlined "✕ Reject" with red tint bg
   - Right: Green outlined "✓ Approve" with green tint bg
   - Strong haptic on approve (HapticManager.success)
   - Double-tap haptic on reject (HapticManager.reject)
   - After action: auto-navigate back to TerminalView

Behavior:
- Tap Approve → POST /api/sessions/:id/approve { toolUseId, decision: "approve" }
- Tap Reject → POST /api/sessions/:id/approve { toolUseId, decision: "reject" }
- Timeout: if no action in 5 minutes, show "Auto-rejecting..." warning, then auto-reject
- If multiple files: batch approval — "Approve All" / "Reject All" buttons appear at bottom

### Components/DiffLineView.swift
Single diff line component:
```swift
struct DiffLineView: View {
    let lineNumber: Int
    let type: DiffLineType  // .added, .removed, .context
    let content: String
    // Monospace, colored, with line number and +/- prefix
}
```

### Models/DiffFile.swift
```swift
struct DiffFile: Identifiable {
    let id: String  // toolUseId
    let filePath: String
    let additions: Int
    let deletions: Int
    let lines: [DiffLine]
    let summary: String?  // From Haiku summarizer

    struct DiffLine {
        let number: Int
        let type: DiffLineType
        let content: String
    }

    enum DiffLineType { case added, removed, context }
}
```

### Views/SettingsView.swift
Settings organized in sections:

1. **Bridge Server**: Host (text), Port (stepper), Status (read-only with StatusDot), Tailscale IP (text), Re-pair button (orange) → re-opens pairing flow
2. **Voice**: Auto-send toggle (with delay stepper 0.5-3.0s), TTS Output toggle, Language picker (English default)
3. **Display**: Font size picker (10/12/14 pt), Auto-scroll toggle, Streaming animation toggle
4. **Notifications**: Toggle per type — Approval needed, Task complete, Errors, Session idle

All settings stored in UserDefaults, synced to companion iOS app via WatchConnectivity.

### Complications/SessionCountComplication.swift
Watch face complications (WidgetKit):
- **Circular**: Active session count number, colored by worst status (green all good, yellow any waiting, red any error)
- **Rectangular**: "WristCode" label + session count + status text
- **Inline**: PixelMascot icon + "N sessions"
- Tap any complication → opens app to session browser
- Background refresh: update complication every 15 minutes with session status

### iOS Companion App (minimal)
```
WristCodeiOS/
  WristCodeiOSApp.swift       # Minimal app entry
  Views/SetupView.swift        # Bridge server configuration (IP, port, pairing code)
  Views/TailscaleConfigView.swift  # Tailscale IP input + connection test
  Services/WatchConnectivity.swift # WCSession to sync config to watch
```
The iOS app is just a settings portal — all real interaction happens on the watch.

### Final Polish Checklist
- [ ] Loading states: Terminal-style "..." blinking dots animation
- [ ] Error states: Red text with retry button
- [ ] Empty states: "No sessions found. Start Claude Code on your Mac." with PixelMascot
- [ ] Smooth NavigationStack transitions (no jarring push animations)
- [ ] Digital Crown scroll sensitivity tuned for terminal view
- [ ] Background app refresh for session status updates
- [ ] VoiceOver accessibility: all elements labeled for screen reader
- [ ] App icon: Orange pixel mascot on dark background (#0F1117)
- [ ] Launch screen: Dark bg with centered PixelMascot + "WristCode" text
- [ ] Memory: purge old messages when > 500 in terminal history
- [ ] Battery: disconnect SSE when app moves to background, reconnect on foreground
- [ ] Crash-free: guard all force unwraps, handle nil sessions gracefully
