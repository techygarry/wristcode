import SwiftUI

struct TerminalMessage: Identifiable {
    let id: UUID
    let type: MessageType
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), type: MessageType, content: String, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
    }

    // MARK: - Message Type

    enum MessageType {
        case userPrompt
        case assistantText
        case toolUse(name: String)
        case toolResult
        case filePath
        case error
        case success
        case cost(input: Int, output: Int, cost: Double)
        case summary(String)

        var color: Color {
            switch self {
            case .userPrompt:       return TerminalTheme.orange
            case .assistantText:    return TerminalTheme.text
            case .toolUse:          return TerminalTheme.cyan
            case .toolResult:       return TerminalTheme.blue
            case .filePath:         return TerminalTheme.cyan
            case .error:            return TerminalTheme.red
            case .success:          return TerminalTheme.green
            case .cost:             return TerminalTheme.textDim
            case .summary:          return TerminalTheme.yellow
            }
        }

        var prefix: String {
            switch self {
            case .userPrompt:           return "> "
            case .assistantText:        return ""
            case .toolUse(let name):    return "~ \(name) "
            case .toolResult:           return "  "
            case .filePath:             return "  "
            case .error:                return "! "
            case .success:              return "+ "
            case .cost:                 return "$ "
            case .summary:              return "# "
            }
        }
    }
}
