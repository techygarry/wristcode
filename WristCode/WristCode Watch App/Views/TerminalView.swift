import SwiftUI

// MARK: - Terminal View

struct TerminalView: View {
    let sessionId: String

    @EnvironmentObject var bridge: BridgeConnection
    @StateObject private var voice = VoiceEngine()

    @State private var messages: [TerminalMessage] = []
    @State private var streamingText: String = ""
    @State private var isStreaming: Bool = false
    @State private var isListening: Bool = false
    @State private var inputText: String = ""
    @State private var showCommandPalette: Bool = false
    @State private var showDiffView: Bool = false
    @State private var showPreview: Bool = false
    @State private var pendingDiffFiles: [DiffFile] = []
    @State private var pendingToolUseId: String = ""
    @State private var cursorVisible: Bool = true
    @State private var cursorTimer: Timer?
    @State private var isWaiting: Bool = false

    private let quickActions = ["Status?", "Continue", "Fix it", "Preview", "Commit"]

    private var currentSession: Session? {
        bridge.sessions.first { $0.id == sessionId }
    }

    private var projectName: String {
        currentSession?.projectName ?? "terminal"
    }

    private var modelName: String {
        currentSession?.model ?? "claude"
    }

    private var connectionColor: Color {
        switch bridge.connectionState {
        case .connected:    return TerminalTheme.green
        case .connecting:   return TerminalTheme.yellow
        case .searching:    return TerminalTheme.yellow
        case .error:        return TerminalTheme.red
        case .disconnected: return TerminalTheme.textDim
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            terminalHeader
            messageList
            quickActionsBar
            inputBar
        }
        .background(TerminalTheme.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(sessionId: sessionId)
        }
        .navigationDestination(isPresented: $showDiffView) {
            DiffView(
                files: pendingDiffFiles,
                toolUseId: pendingToolUseId,
                sessionId: sessionId
            )
        }
        .navigationDestination(isPresented: $showPreview) {
            PreviewBrowserView(sessionId: sessionId)
        }
        .onAppear {
            startCursorBlink()
            bridge.connectStream(sessionId: sessionId)
            messages = bridge.currentMessages
        }
        .onDisappear {
            cursorTimer?.invalidate()
            cursorTimer = nil
        }
        .onChange(of: bridge.currentMessages.count) {
            messages = bridge.currentMessages
        }
    }

    // MARK: - Header

    private var terminalHeader: some View {
        HStack(spacing: 2) {
            PixelMascot(size: 7)
            Text(projectName)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.orange)
                .lineLimit(1)
            Spacer()
            StatusDot(
                color: connectionColor,
                size: 3,
                pulse: {
                    if case .connecting = bridge.connectionState { return true }
                    return false
                }()
            )
            Text(modelName)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
                .lineLimit(1)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(TerminalTheme.bgCard)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(messages) { message in
                        TerminalTextView(message: message)
                            .id(message.id)
                    }

                    // Streaming text with blinking cursor
                    if isStreaming {
                        streamingRow
                    }

                    if isWaiting {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.5)
                            Text("Claude is working...")
                                .font(TerminalTheme.monoFont)
                                .foregroundColor(TerminalTheme.orange)
                        }
                        .padding(.vertical, 4)
                    }

                    // Invisible anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .onChange(of: messages.count) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: streamingText) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var streamingRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(streamingText)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.text)
            Text("\u{2588}")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.orange)
                .opacity(cursorVisible ? 1 : 0)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(quickActions, id: \.self) { action in
                    Button {
                        sendQuickAction(action)
                    } label: {
                        Text(action)
                            .font(TerminalTheme.monoFont)
                            .foregroundColor(TerminalTheme.text)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 2)
                            .background(TerminalTheme.bgCard)
                            .cornerRadius(TerminalTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                                    .stroke(TerminalTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    // MARK: - Input Bar (compact)

    private var inputBar: some View {
        HStack(spacing: 3) {
            TextField("prompt...", text: $inputText)
                .font(TerminalTheme.monoFont)

            if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(TerminalTheme.orange)
                }
                .buttonStyle(.plain)
            }

            Button { showCommandPalette = true } label: {
                Text("/")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.orange)
                    .frame(width: 16, height: 16)
                    .background(TerminalTheme.bgCard)
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(TerminalTheme.inputBg)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        sendText(text)
    }

    private func sendQuickAction(_ action: String) {
        if action == "Preview" {
            showPreview = true
            return
        }
        sendText(action)
    }

    private func sendText(_ text: String) {
        HapticManager.click()
        let userMsg = TerminalMessage(type: .userPrompt, content: text)
        messages.append(userMsg)
        bridge.currentMessages.append(userMsg)
        isWaiting = true

        Task {
            do {
                try await bridge.sendPrompt(sessionId: sessionId, prompt: text)
                await MainActor.run {
                    isWaiting = false
                    messages = bridge.currentMessages
                    // Auto-open preview if a website was built
                    if bridge.lastHasPreview {
                        showPreview = true
                    }
                }
            } catch {
                await MainActor.run {
                    isWaiting = false
                    let errMsg = TerminalMessage(type: .error, content: "Failed: \(error.localizedDescription)")
                    messages.append(errMsg)
                    bridge.currentMessages.append(errMsg)
                }
            }
        }
    }

    private func toggleVoice() {
        isListening.toggle()
        if isListening {
            voice.startListening()
            HapticManager.click()
        } else {
            voice.stopListening()
            if !voice.transcription.isEmpty {
                inputText = voice.transcription
            }
        }
    }

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }
}
