import SwiftUI

// MARK: - Diff View

struct DiffView: View {
    let files: [DiffFile]
    let toolUseId: String
    let sessionId: String

    @EnvironmentObject var bridge: BridgeConnection
    @Environment(\.dismiss) private var dismiss

    @State private var currentFileIndex: Int = 0

    private var totalAdditions: Int {
        files.reduce(0) { $0 + $1.additions }
    }

    private var totalDeletions: Int {
        files.reduce(0) { $0 + $1.deletions }
    }

    var body: some View {
        VStack(spacing: 0) {
            diffHeader
            aiSummary
            fileContent
            actionButtons
        }
        .background(TerminalTheme.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var diffHeader: some View {
        HStack {
            Text("Review Changes")
                .font(TerminalTheme.monoHeader)
                .foregroundColor(TerminalTheme.orange)
            Spacer()
            Text("\(files.count) files")
                .font(TerminalTheme.monoFont)
                .foregroundColor(TerminalTheme.yellow)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
                .background(TerminalTheme.yellow.opacity(0.15))
                .cornerRadius(TerminalTheme.cornerRadius)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }

    // MARK: - AI Summary

    private var aiSummary: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                Text("\u{1F916}")
                    .font(.system(size: 7))
                Text("Summary")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.orange)
            }

            if let summary = files.first?.summary, !summary.isEmpty {
                Text(summary)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                    .lineLimit(3)
            } else {
                Text("\(files.count) files changed, +\(totalAdditions) -\(totalDeletions)")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
            }
        }
        .padding(3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TerminalTheme.bgCard)
        .cornerRadius(TerminalTheme.cornerRadius)
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }

    // MARK: - File Content (Paged)

    private var fileContent: some View {
        TabView(selection: $currentFileIndex) {
            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                singleFileView(file)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: files.count > 1 ? .automatic : .never))
    }

    private func singleFileView(_ file: DiffFile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                Text(file.fileName)
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.cyan)
                    .lineLimit(1)
                Spacer()
                Text("+\(file.additions)")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.green)
                Text("-\(file.deletions)")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.red)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(TerminalTheme.bgCard)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(file.lines) { line in
                        DiffLineView(line: line)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Button {
                HapticManager.reject()
                Task {
                    try? await bridge.sendApproval(sessionId: sessionId, approved: false)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 2) {
                    Text("\u{2715}")
                        .font(.system(size: 7))
                    Text("Reject")
                        .font(TerminalTheme.monoFont)
                }
                .foregroundColor(TerminalTheme.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(TerminalTheme.red.opacity(0.15))
                .cornerRadius(TerminalTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                        .stroke(TerminalTheme.red.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.success()
                Task {
                    try? await bridge.sendApproval(sessionId: sessionId, approved: true)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 2) {
                    Text("\u{2713}")
                        .font(.system(size: 7))
                    Text("Approve")
                        .font(TerminalTheme.monoFont)
                }
                .foregroundColor(TerminalTheme.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(TerminalTheme.green.opacity(0.15))
                .cornerRadius(TerminalTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                        .stroke(TerminalTheme.green.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }
}
