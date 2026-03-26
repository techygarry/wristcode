import SwiftUI

// MARK: - Session

struct Session: Identifiable, Codable, Hashable {
    let id: String
    let cwd: String
    let model: String
    var status: SessionStatus
    var lastActive: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cwd = try container.decodeIfPresent(String.self, forKey: .cwd) ?? "/tmp/session"
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? "sonnet"
        status = try container.decodeIfPresent(SessionStatus.self, forKey: .status) ?? .idle
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
    }

    var projectName: String {
        URL(fileURLWithPath: cwd).lastPathComponent
    }
}

// MARK: - Session Status

enum SessionStatus: String, Codable {
    case running
    case waiting
    case idle
    case error

    var color: Color {
        switch self {
        case .running:  return TerminalTheme.green
        case .waiting:  return TerminalTheme.yellow
        case .idle:     return TerminalTheme.textDim
        case .error:    return TerminalTheme.red
        }
    }

    var label: String {
        rawValue.capitalized
    }
}
