import SwiftUI

@main
struct WristCodeApp: App {
    @StateObject private var bridgeConnection = BridgeConnection()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bridgeConnection)
                .preferredColorScheme(.dark)
        }
    }
}
