import SwiftUI

struct PreviewBrowserView: View {
    let sessionId: String
    @EnvironmentObject var bridge: BridgeConnection
    @Environment(\.openURL) private var openURL
    @State private var pageTitle: String = ""
    @State private var pageSummary: String = ""
    @State private var isLoading: Bool = true

    private let tunnelBase = "respiratory-ppm-hardcover-gym.trycloudflare.com"

    private var localPreviewURL: URL? {
        let host = bridge.config.host.isEmpty ? "localhost" : bridge.config.host
        let scheme = bridge.config.port == 443 ? "https" : "http"
        let portSuffix = (bridge.config.port == 443 || bridge.config.port == 80) ? "" : ":\(bridge.config.port)"
        return URL(string: "\(scheme)://\(host)\(portSuffix)/preview/\(sessionId)")
    }

    private var phoneURL: String {
        "https://\(tunnelBase)/preview/\(sessionId)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 3) {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalTheme.cyan)
                    Text("Preview")
                        .font(TerminalTheme.monoHeader)
                        .foregroundColor(TerminalTheme.orange)
                    Spacer()
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    // Page title
                    if !pageTitle.isEmpty {
                        Text(pageTitle)
                            .font(TerminalTheme.monoBody)
                            .foregroundColor(TerminalTheme.text)
                    }

                    // Summary
                    if !pageSummary.isEmpty {
                        Text(pageSummary)
                            .font(TerminalTheme.monoFont)
                            .foregroundColor(TerminalTheme.textDim)
                            .lineLimit(6)
                    }

                    // Divider
                    Rectangle()
                        .fill(TerminalTheme.border)
                        .frame(height: 1)
                        .padding(.vertical, 2)

                    // Open on iPhone button
                    Button {
                        if let url = URL(string: phoneURL) {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone")
                                .font(.system(size: 12))
                            Text("Open on iPhone")
                                .font(TerminalTheme.monoBody)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(TerminalTheme.orange)
                        .cornerRadius(TerminalTheme.cornerRadius)
                    }
                    .buttonStyle(.plain)

                    // URL for manual access
                    Text(phoneURL)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.cyan)
                        .lineLimit(3)

                    // Status indicator
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(TerminalTheme.green)
                        Text("Website ready")
                            .font(TerminalTheme.monoFont)
                            .foregroundColor(TerminalTheme.green)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(TerminalTheme.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        guard let url = localPreviewURL else {
            isLoading = false
            return
        }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let html = String(data: data, encoding: .utf8) ?? ""
                await MainActor.run {
                    pageTitle = extractTitle(html)
                    pageSummary = extractSummary(html)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    pageTitle = "Website Built"
                    pageSummary = "Ready to view"
                    isLoading = false
                }
            }
        }
    }

    private func extractTitle(_ html: String) -> String {
        if let s = html.range(of: "<title>"), let e = html.range(of: "</title>") {
            return String(html[s.upperBound..<e.lowerBound])
        }
        return "Website"
    }

    private func extractSummary(_ html: String) -> String {
        let stripped = html
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let words = stripped.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.prefix(25).joined(separator: " ") + (words.count > 25 ? "..." : "")
    }
}
