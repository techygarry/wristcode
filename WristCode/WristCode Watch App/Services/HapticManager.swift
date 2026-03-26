import WatchKit

// MARK: - Haptic Manager

struct HapticManager {
    static func success() {
        WKInterfaceDevice.current().play(.success)
    }

    static func approval() {
        WKInterfaceDevice.current().play(.notification)
    }

    static func click() {
        WKInterfaceDevice.current().play(.click)
    }

    static func reject() {
        WKInterfaceDevice.current().play(.failure)
    }

    static func error() {
        WKInterfaceDevice.current().play(.retry)
    }
}
