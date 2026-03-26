import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject var bridge: BridgeConnection
    @State private var dotCount: Int = 0
    @State private var dotTimer: Timer?

    // Rotating tips
    private let tips: [String] = [
        "Swipe to browse sessions",
        "Tap mic for voice input",
        "Use /commands for actions",
        "Review diffs on your wrist",
    ]
    @State private var tipIndex: Int = 0
    @State private var tipTimer: Timer?
    @State private var newSessionId: String?
    @State private var navigateToNewSession: Bool = false
    @State private var showNewSessionSheet: Bool = false
    @State private var selectedModel: String = "sonnet"

    // Slash commands shown inline
    private struct SlashCmd: Identifiable {
        let id = UUID()
        let name: String
        let desc: String
    }

    private let slashCommands: [SlashCmd] = [
        SlashCmd(name: "help", desc: "Show commands"),
        SlashCmd(name: "clear", desc: "Clear output"),
        SlashCmd(name: "compact", desc: "Compact history"),
        SlashCmd(name: "status", desc: "Session status"),
        SlashCmd(name: "cost", desc: "Token usage"),
    ]

    // Mock recent sessions for display
    private var recentSessions: [Session] {
        Array(bridge.sessions.prefix(3))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                topBar
                versionBadge
                welcomeRow
                modelInfo
                connectionCard
                recentActivitySection
                commandPrompt
                slashCommandsList
                newSessionButton
            }
            .padding(.horizontal, 2)
        }
        .background(TerminalTheme.bg)
        .onAppear { startTimers() }
        .onDisappear { stopTimers() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 2) {
            PixelMascot(size: 8)
            Text("claude")
                .font(TerminalTheme.monoHeader)
                .foregroundColor(TerminalTheme.text)
            Text("+")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
            Spacer()
            Text("\u{2500}")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
            Text("\u{00D7}")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
        }
        .padding(.vertical, 1)
    }

    // MARK: - Version Badge

    private var versionBadge: some View {
        Text("WristCode v1.0.0")
            .font(TerminalTheme.monoFont)
            .foregroundColor(TerminalTheme.orange)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .overlay(
                RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                    .stroke(TerminalTheme.orange, lineWidth: 1)
            )
    }

    // MARK: - Welcome + Tips Row

    private var welcomeRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Welcome back!")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(TerminalTheme.text)

            HStack(alignment: .top, spacing: 3) {
                PixelMascot(size: 28)
                tipsBox
            }
        }
    }

    private var tipsBox: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Tips for getting started")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.orange)
            Text(tips[tipIndex % tips.count])
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                .stroke(TerminalTheme.orange.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Model Info

    private var modelInfo: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                Text("Sonnet 4.5")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.text)
                Text("\u{00B7}")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                Text("Claude")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
            }
            Text("~/projects/wristcode")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim.opacity(0.6))
        }
        .padding(.vertical, 1)
    }

    // MARK: - Connection Card

    private var connectionCard: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1)
                .fill(connectionColor)
                .frame(width: 2)

            StatusDot(
                color: connectionColor,
                size: 4,
                pulse: isConnecting
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(connectionLabel)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(connectionColor)
                if !bridge.config.host.isEmpty {
                    Text(bridge.config.host)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(3)
        .background(TerminalTheme.bgCard)
        .cornerRadius(TerminalTheme.cornerRadius)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            NavigationLink(destination: SessionBrowserView()) {
                HStack {
                    Text("Recent activity")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.orange)
                    Spacer()
                    Text("\(bridge.sessions.count)")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 6))
                        .foregroundColor(TerminalTheme.textDim)
                }
            }
            .buttonStyle(.plain)

            if recentSessions.isEmpty {
                Text("No recent activity")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                    .padding(.vertical, 1)
            } else {
                ForEach(recentSessions) { session in
                    NavigationLink(destination: TerminalView(sessionId: session.id)) {
                        sessionRow(session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: 2) {
            StatusDot(color: session.status.color, size: 3)
            Text(session.projectName)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.text)
                .lineLimit(1)
            Spacer()
            Text(session.lastActive.timeAgoShort)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
        }
        .padding(.vertical, 1)
    }

    // MARK: - Command Prompt

    private var commandPrompt: some View {
        NavigationLink(destination: TerminalView(sessionId: bridge.sessions.first?.id ?? "")) {
            HStack(spacing: 2) {
                Text("= /")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.blue)
                Text("type a command" + String(repeating: ".", count: dotCount))
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                Spacer()
            }
            .padding(2)
            .background(TerminalTheme.inputBg)
            .cornerRadius(TerminalTheme.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inline Slash Commands

    private var slashCommandsList: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(slashCommands) { cmd in
                HStack(spacing: 0) {
                    Text("/")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.orange)
                    Text(cmd.name)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.text)
                    Spacer()
                    Text(cmd.desc)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim)
                }
                .padding(.vertical, 1)
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - New Session Button

    private var newSessionButton: some View {
        Button {
            showNewSessionSheet = true
        } label: {
            HStack(spacing: 2) {
                Text("+").font(TerminalTheme.monoFont).foregroundColor(TerminalTheme.orange)
                Text("New Session").font(TerminalTheme.monoFont).foregroundColor(TerminalTheme.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                    .stroke(TerminalTheme.orange, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showNewSessionSheet) {
            newSessionSheet
        }
        .navigationDestination(isPresented: $navigateToNewSession) {
            TerminalView(sessionId: newSessionId ?? "")
        }
    }

    private var newSessionSheet: some View {
        VStack(spacing: 6) {
            Text("New Session")
                .font(TerminalTheme.monoHeader)
                .foregroundColor(TerminalTheme.orange)

            // Model picker
            VStack(alignment: .leading, spacing: 2) {
                Text("Model")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                Picker("Model", selection: $selectedModel) {
                    Text("Sonnet 4.5").tag("sonnet")
                    Text("Opus 4.6").tag("opus")
                    Text("Haiku 4.5").tag("haiku")
                }
                .pickerStyle(.automatic)
                .tint(TerminalTheme.orange)
            }

            Button {
                showNewSessionSheet = false
                HapticManager.click()
                Task {
                    do {
                        let session = try await bridge.createSession(
                            cwd: "/Users/adsol/Documents/techy-projects/watchvibe/sandbox",
                            model: selectedModel
                        )
                        newSessionId = session.id
                        navigateToNewSession = true
                    } catch {}
                }
            } label: {
                Text("Start")
                    .font(TerminalTheme.monoBody)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(TerminalTheme.orange)
                    .cornerRadius(TerminalTheme.cornerRadius)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(TerminalTheme.bg)
    }

    // MARK: - Connection Helpers

    private var connectionColor: Color {
        switch bridge.connectionState {
        case .disconnected:     return TerminalTheme.textDim
        case .searching:        return TerminalTheme.yellow
        case .connecting:       return TerminalTheme.yellow
        case .connected:        return TerminalTheme.green
        case .error:            return TerminalTheme.red
        }
    }

    private var connectionLabel: String {
        switch bridge.connectionState {
        case .disconnected:         return "Disconnected"
        case .searching:            return "Searching..."
        case .connecting:           return "Connecting..."
        case .connected:            return "Connected"
        case .error(let message):   return "Error: \(message)"
        }
    }

    private var isConnecting: Bool {
        if case .connecting = bridge.connectionState { return true }
        if case .searching = bridge.connectionState { return true }
        return false
    }

    // MARK: - Timers

    private func startTimers() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
        tipTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                tipIndex = (tipIndex + 1) % tips.count
            }
        }
    }

    private func stopTimers() {
        dotTimer?.invalidate()
        dotTimer = nil
        tipTimer?.invalidate()
        tipTimer = nil
    }
}

// MARK: - Date Extension

extension Date {
    var timeAgoShort: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
}
