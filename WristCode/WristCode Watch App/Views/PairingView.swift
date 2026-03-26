import SwiftUI

// MARK: - Pairing View

struct PairingView: View {
    @EnvironmentObject var bridge: BridgeConnection

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var focusedIndex: Int = 0
    @State private var errorMessage: String?
    @State private var isPairing: Bool = false

    private var fullCode: String {
        digits.joined()
    }

    private var isCodeComplete: Bool {
        fullCode.count == 6 && digits.allSatisfy { !$0.isEmpty }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                Spacer().frame(height: 8)

                // Mascot
                PixelMascot(size: 36)

                // Title
                Text("Enter Pairing Code")
                    .font(TerminalTheme.monoHeader)
                    .foregroundColor(TerminalTheme.text)

                // Subtitle
                Text("Run 'wristcode pair' on your Mac")
                    .font(TerminalTheme.monoFont)
                    .foregroundColor(TerminalTheme.textDim)
                    .multilineTextAlignment(.center)

                // Digit input
                digitFields

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(TerminalTheme.monoFont)
                        .foregroundColor(TerminalTheme.red)
                        .multilineTextAlignment(.center)
                }

                // Pair button
                pairButton

                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 8)
        }
        .background(TerminalTheme.bg)
        .onChange(of: bridge.connectionState) {
            if bridge.connectionState.isConnected {
                isPairing = false
            } else if case .error(let message) = bridge.connectionState {
                isPairing = false
                errorMessage = message
            }
        }
    }

    // MARK: - Digit Fields

    private var digitFields: some View {
        HStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { index in
                digitBox(index: index)
            }
        }
    }

    private func digitBox(index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                .stroke(
                    index == focusedIndex
                        ? TerminalTheme.orange
                        : TerminalTheme.border,
                    lineWidth: index == focusedIndex ? 1.5 : 1
                )
                .background(
                    RoundedRectangle(cornerRadius: TerminalTheme.cornerRadius)
                        .fill(TerminalTheme.inputBg)
                )

            Text(digits[index].isEmpty ? "_" : digits[index])
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(
                    digits[index].isEmpty
                        ? TerminalTheme.textDim.opacity(0.3)
                        : TerminalTheme.orange
                )
        }
        .frame(width: 24, height: 30)
        .onTapGesture {
            focusedIndex = index
        }
    }

    // MARK: - Pair Button

    private var pairButton: some View {
        Button {
            attemptPairing()
        } label: {
            HStack(spacing: 4) {
                if isPairing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.6)
                        .tint(TerminalTheme.bg)
                }
                Text(isPairing ? "Pairing..." : "Pair")
                    .font(TerminalTheme.monoHeader)
                    .foregroundColor(TerminalTheme.bg)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isCodeComplete
                    ? TerminalTheme.orange
                    : TerminalTheme.orange.opacity(0.3)
            )
            .cornerRadius(TerminalTheme.cornerRadius)
        }
        .buttonStyle(.plain)
        .disabled(!isCodeComplete || isPairing)
    }

    // MARK: - Pairing

    private func attemptPairing() {
        errorMessage = nil
        isPairing = true
        HapticManager.click()
        Task {
            do {
                try await bridge.pair(code: fullCode)
            } catch {
                await MainActor.run {
                    isPairing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
