import SwiftUI

/// Claude mascot matching the WristCode logo: orange body, > < eyes, gap mouth, feet
struct PixelMascot: View {
    let size: CGFloat

    init(size: CGFloat = 16) {
        self.size = size
    }

    private var p: CGFloat { size / 9 }

    // 0=clear, 1=orange body, 2=dark (eyes/mouth)
    private let grid: [[Int]] = [
        [0, 0, 1, 1, 0, 1, 1, 0, 0],  // antennae
        [0, 1, 1, 1, 1, 1, 1, 1, 0],  // top head
        [1, 1, 2, 1, 1, 1, 2, 1, 1],  // eyes row (> <)
        [1, 2, 2, 1, 1, 1, 2, 2, 1],  // eyes lower
        [1, 1, 1, 1, 1, 1, 1, 1, 1],  // mid body
        [1, 1, 1, 1, 1, 1, 1, 1, 1],  // body
        [1, 1, 0, 0, 0, 0, 0, 1, 1],  // mouth gap
        [1, 1, 0, 1, 0, 1, 0, 1, 1],  // lower with legs
        [0, 0, 0, 1, 0, 1, 0, 0, 0],  // feet
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let px = canvasSize.width / 9
            for row in 0..<9 {
                for col in 0..<9 {
                    let val = grid[row][col]
                    guard val != 0 else { continue }
                    let color: Color = val == 1 ? TerminalTheme.orange : Color(hex: "2A2A2A")
                    let rect = CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px + 0.5, height: px + 0.5)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: size, height: size)
    }
}
