import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var bridge: BridgeConnection

    // Bridge Server
    @AppStorage("bridge_host") private var host: String = "192.168.1.100"
    @AppStorage("bridge_port") private var port: Int = 3847
    @AppStorage("bridge_tailscale_ip") private var tailscaleIP: String = ""

    // Voice
    @AppStorage("voice_auto_send") private var autoSend: Bool = true
    @AppStorage("voice_tts") private var ttsEnabled: Bool = false
    @AppStorage("voice_language") private var language: String = "en-US"

    // Display
    @AppStorage("display_font_size") private var fontSize: Int = 10
    @AppStorage("display_auto_scroll") private var autoScroll: Bool = true
    @AppStorage("display_streaming") private var streamingEnabled: Bool = true

    // Notifications
    @AppStorage("notify_approval") private var notifyApproval: Bool = true
    @AppStorage("notify_complete") private var notifyComplete: Bool = true
    @AppStorage("notify_errors") private var notifyErrors: Bool = true

    private let fontSizes = [7, 8, 9, 10, 11]
    private let languages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "ja-JP"]

    private var connectionColor: Color {
        switch bridge.connectionState {
        case .connected:    return TerminalTheme.green
        case .connecting:   return TerminalTheme.yellow
        case .searching:    return TerminalTheme.yellow
        case .error:        return TerminalTheme.red
        case .disconnected: return TerminalTheme.textDim
        }
    }

    private var connectionLabel: String {
        switch bridge.connectionState {
        case .disconnected:         return "Disconnected"
        case .searching:            return "Searching"
        case .connecting:           return "Connecting"
        case .connected:            return "Connected"
        case .error(let message):   return message
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                bridgeSection
                voiceSection
                displaySection
                notificationsSection
                footer
            }
            .padding(.horizontal, 2)
        }
        .background(TerminalTheme.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Bridge Server Section

    private var bridgeSection: some View {
        settingsSection(title: "Bridge Server") {
            settingsRow(label: "Host") {
                Text(host)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.text)
                    .lineLimit(1)
            }

            settingsRow(label: "Port") {
                Text("\(port)")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.text)
            }

            settingsRow(label: "Status") {
                HStack(spacing: 2) {
                    StatusDot(color: connectionColor, size: 3)
                    Text(connectionLabel)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(connectionColor)
                }
            }

            if !tailscaleIP.isEmpty {
                settingsRow(label: "Tailscale") {
                    Text(tailscaleIP)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.cyan)
                        .lineLimit(1)
                }
            }

            Button {
                bridge.config.jwtToken = nil
                bridge.disconnect()
            } label: {
                HStack {
                    Spacer()
                    Text("Re-pair")
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.orange)
                    Spacer()
                }
                .padding(.vertical, 3)
                .overlay(
                    RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                        .stroke(TerminalTheme.orange, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Voice Section

    private var voiceSection: some View {
        settingsSection(title: "Voice") {
            settingsToggle(label: "Auto-send", isOn: $autoSend)
            settingsToggle(label: "TTS", isOn: $ttsEnabled)

            settingsRow(label: "Language") {
                Picker("", selection: $language) {
                    ForEach(languages, id: \.self) { lang in
                        Text(lang)
                            .font(TerminalTheme.monoFont)
                            .tag(lang)
                    }
                }
                .pickerStyle(.automatic)
                .tint(TerminalTheme.orange)
            }
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        settingsSection(title: "Display") {
            settingsRow(label: "Font size") {
                Picker("", selection: $fontSize) {
                    ForEach(fontSizes, id: \.self) { size in
                        Text("\(size)pt")
                            .font(TerminalTheme.monoFont)
                            .tag(size)
                    }
                }
                .pickerStyle(.automatic)
                .tint(TerminalTheme.orange)
            }

            settingsToggle(label: "Auto-scroll", isOn: $autoScroll)
            settingsToggle(label: "Streaming", isOn: $streamingEnabled)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        settingsSection(title: "Notifications") {
            settingsToggle(label: "Approvals", isOn: $notifyApproval)
            settingsToggle(label: "Complete", isOn: $notifyComplete)
            settingsToggle(label: "Errors", isOn: $notifyErrors)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 1) {
            Text("WristCode v1.0.0")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
            Text("Claude Agent SDK")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(TerminalTheme.monoHeader)
                .foregroundColor(TerminalTheme.orange)
                .padding(.bottom, 1)

            VStack(spacing: 1) {
                content()
            }
            .padding(3)
            .background(TerminalTheme.bgCard)
            .cornerRadius(TerminalTheme.cornerRadius)
        }
    }

    private func settingsRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
            Spacer()
            content()
        }
        .padding(.vertical, 1)
    }

    private func settingsToggle(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
        }
        .tint(TerminalTheme.orange)
        .padding(.vertical, 1)
    }
}
