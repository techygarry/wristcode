import Foundation

struct BridgeConfig: Codable {
    var host: String = "localhost"
    var port: Int = 3847
    var tailscaleIP: String = ""
    var pairingCode: String = ""
    var jwtToken: String?

    var isPaired: Bool { jwtToken != nil }
}
