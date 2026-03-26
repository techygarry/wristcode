import SwiftUI

// MARK: - Diff File

struct DiffFile: Identifiable {
    let id: String
    let filePath: String
    let additions: Int
    let deletions: Int
    let lines: [DiffLine]
    let summary: String?

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
}

// MARK: - Diff Line

struct DiffLine: Identifiable {
    let id = UUID()
    let number: Int
    let type: DiffLineType
    let content: String
}

// MARK: - Diff Line Type

enum DiffLineType {
    case added
    case removed
    case context

    var color: Color {
        switch self {
        case .added:    return TerminalTheme.green
        case .removed:  return TerminalTheme.red
        case .context:  return TerminalTheme.textDim
        }
    }

    var prefix: String {
        switch self {
        case .added:    return "+"
        case .removed:  return "-"
        case .context:  return " "
        }
    }

    var backgroundColor: Color {
        switch self {
        case .added:    return TerminalTheme.green.opacity(0.1)
        case .removed:  return TerminalTheme.red.opacity(0.1)
        case .context:  return Color.clear
        }
    }
}

// MARK: - Sample Data

extension DiffFile {
    static let sampleFiles: [DiffFile] = [
        DiffFile(
            id: "tool-1",
            filePath: "src/middleware/auth.ts",
            additions: 5,
            deletions: 1,
            lines: [
                DiffLine(number: 14, type: .context, content: "export const authenticate = async (req, res) => {"),
                DiffLine(number: 15, type: .removed, content: "  const { email, password } = req.body;"),
                DiffLine(number: 15, type: .added, content: "  const { email, password } = req.body;"),
                DiffLine(number: 16, type: .added, content: "  if (!email || !isValidEmail(email)) {"),
                DiffLine(number: 17, type: .added, content: "    return res.status(400).json({"),
                DiffLine(number: 18, type: .added, content: "      error: \"Invalid email format\""),
                DiffLine(number: 19, type: .added, content: "    });"),
                DiffLine(number: 20, type: .added, content: "  }"),
                DiffLine(number: 21, type: .context, content: "  const user = await User.findOne({ email });"),
            ],
            summary: "Added email validation to auth middleware. Returns 400 for invalid inputs."
        )
    ]
}
