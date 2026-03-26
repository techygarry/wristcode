import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bridge: BridgeConnection

    var body: some View {
        NavigationStack {
            WelcomeView()
        }
        .background(TerminalTheme.bg)
        .environment(\.font, TerminalTheme.monoBody)
    }
}
