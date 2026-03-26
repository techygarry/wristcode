# WristCode — Session 6: Connection + Session Browser Views

## Context
Session 5 created the Xcode project with theme system and models. Now build the networking services and the first two screens: Welcome + Session Browser.

## Task

### Services/BonjourDiscovery.swift
```swift
class BonjourDiscovery: ObservableObject {
    @Published var state: DiscoveryState = .idle
    @Published var discoveredHost: String?
    @Published var discoveredPort: Int?

    enum DiscoveryState { case idle, searching, found, timeout }

    // Use NWBrowser to find _wristcode._tcp services
    // 3-second timeout, then state = .timeout (triggers Tailscale fallback)
    func startDiscovery()
    func stopDiscovery()
}
```

### Services/TailscaleFallback.swift
```swift
class TailscaleFallback {
    // Read Tailscale IP from BridgeConfig (stored in UserDefaults)
    // Before connecting, hit GET /api/health to verify server is reachable
    // Return (host, port) tuple on success, nil on failure
    static func connect(config: BridgeConfig) async -> (String, Int)?
}
```

### Services/BridgeConnection.swift
Main networking service — ObservableObject for SwiftUI:
```swift
class BridgeConnection: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var sessions: [Session] = []
    @Published var currentMessages: [TerminalMessage] = []

    enum ConnectionState {
        case disconnected, searching, connecting, connected, error(String)
        var statusColor: Color { /* red/orange/yellow/green/red */ }
    }

    // Connection
    func connect() async  // Try Bonjour first, fallback to Tailscale
    func pair(code: String) async throws -> Bool  // POST /api/pair, store JWT in Keychain
    func disconnect()

    // Sessions
    func fetchSessions() async  // GET /api/sessions
    func createSession(cwd: String, model: String) async throws -> Session
    func deleteSession(id: String) async throws

    // SSE (for terminal view — built in next session but define interface)
    func connectStream(sessionId: String) async
    func sendPrompt(sessionId: String, text: String, type: String) async throws
    func sendApproval(sessionId: String, toolUseId: String, decision: String) async throws

    // Internal
    private var baseURL: String { "http://\(host):\(port)" }
    private func request<T: Decodable>(_ method: String, _ path: String, body: Encodable?) async throws -> T
    // JWT from Keychain for Authorization header
    // Auto-reconnect with exponential backoff on connection drop
}
```

### Services/SessionStore.swift
```swift
// SwiftData local cache for offline session list + recent history
@Model class CachedSession {
    var sessionId: String
    var projectName: String
    var model: String
    var lastActive: Date
}
```

### Views/WelcomeView.swift
Replicates Claude Code welcome screen layout:

Layout (top to bottom):
1. **Top bar**: PixelMascot (12pt) + "claude" bold white + "+" dimmed | right: "─" "×" decorative
2. **Version badge**: Orange bordered box "WristCode v1.0.0"
3. **Welcome text**: "Welcome back Garry!" bold white 14pt
4. **Two-column**: PixelMascot (28pt) left | Orange bordered "Tips" box right
5. **Connection card**: Green/orange/red left border, StatusDot + "Connected via Wi-Fi/Tailscale", host:port
6. **Recent activity**: Orange header, list of recent sessions with StatusDot + name + time
7. **Command hint**: Blue "= /" + dimmed "type a command..." with blinking dots

Navigation:
- Tap a recent session → push to TerminalView
- Tap anywhere on connection card when disconnected → push to pairing flow
- First run (no JWT) → show pairing code input (4 digit fields, orange borders)

### Views/SessionBrowserView.swift
Session list screen:

Layout:
1. **Header**: PixelMascot + "Sessions" orange bold | "N active" dimmed right
2. **Session cards** (ForEach): Dark card (#161B22), orange left border on first/selected, project name bold, StatusDot + status label, model + truncated ID, time ago
3. **New session button**: Dashed orange border "+ New Session" — tap opens sheet with directory picker + model selector
4. Pull-to-refresh: calls fetchSessions()
5. Swipe to delete: .swipeActions with red delete button → deleteSession()

Navigation:
- Tap session card → push to TerminalView(sessionId)
