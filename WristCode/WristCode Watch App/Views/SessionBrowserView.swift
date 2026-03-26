import SwiftUI

// MARK: - Session Browser View

struct SessionBrowserView: View {
    @EnvironmentObject var bridge: BridgeConnection

    private var activeSessions: [Session] {
        bridge.sessions.filter { $0.status == .running || $0.status == .waiting }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 3) {
                header
                sessionList
                newSessionButton
            }
            .padding(.horizontal, 2)
        }
        .background(TerminalTheme.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await bridge.fetchSessions() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 2) {
            PixelMascot(size: 8)
            Text("Sessions")
                .font(TerminalTheme.monoHeader)
                .foregroundColor(TerminalTheme.orange)
            Spacer()
            Text("\(activeSessions.count) active")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim)
        }
        .padding(.vertical, 1)
    }

    // MARK: - Session List

    private var sessionList: some View {
        VStack(spacing: 2) {
            if bridge.sessions.isEmpty {
                emptyState
            } else {
                ForEach(bridge.sessions) { session in
                    sessionCardLink(session)
                }
            }
        }
    }

    private func sessionCardLink(_ session: Session) -> some View {
        NavigationLink(destination: TerminalView(sessionId: session.id)) {
            sessionCard(session)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    try? await bridge.deleteSession(id: session.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 2) {
            Text("no sessions")
                .font(TerminalTheme.monoBody)
                .foregroundColor(TerminalTheme.textDim)
            Text("create one or connect to bridge")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.textDim.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Session Card

    private func sessionCard(_ session: Session) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(session.status == .running ? TerminalTheme.orange : session.status.color.opacity(0.3))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.projectName)
                    .font(TerminalTheme.monoBody)
                    .foregroundColor(TerminalTheme.text)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    StatusDot(color: session.status.color, size: 3)
                    Text(session.status.label)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(session.status.color)
                }

                HStack(spacing: 2) {
                    Text(session.model)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim)
                    Text(String(session.id.prefix(8)))
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.textDim.opacity(0.5))
                }

                Text(session.lastActive.timeAgoShort)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim.opacity(0.6))
            }
            .padding(.leading, 3)
            .padding(.vertical, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TerminalTheme.bgCard)
        .cornerRadius(TerminalTheme.cornerRadius)
    }

    // MARK: - New Session Button

    private var newSessionButton: some View {
        Button {
            Task {
                _ = try? await bridge.createSession()
            }
        } label: {
            HStack(spacing: 2) {
                Text("+")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.orange)
                Text("New Session")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                    .stroke(TerminalTheme.orange, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}
