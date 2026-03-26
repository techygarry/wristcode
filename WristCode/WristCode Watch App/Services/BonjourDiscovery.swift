import Foundation
import Network
import Combine

// MARK: - Discovery State

enum DiscoveryState: Equatable {
    case idle
    case searching
    case found
    case timeout
}

// MARK: - Bonjour Discovery

final class BonjourDiscovery: ObservableObject {
    @Published var state: DiscoveryState = .idle
    @Published var discoveredHost: String?
    @Published var discoveredPort: Int?

    private var browser: NWBrowser?
    private var timeoutTask: Task<Void, Never>?

    private let serviceType = "_wristcode._tcp"

    deinit {
        stop()
    }

    // MARK: - Public

    func startSearching() {
        guard state != .searching else { return }
        state = .searching
        discoveredHost = nil
        discoveredPort = nil

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] newState in
            DispatchQueue.main.async {
                self?.handleBrowserState(newState)
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            DispatchQueue.main.async {
                self?.handleResults(results)
            }
        }

        browser.start(queue: .main)
        self.browser = browser

        // 5-second timeout
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            if self?.state == .searching {
                self?.state = .timeout
                self?.stop()
            }
        }
    }

    func stop() {
        browser?.cancel()
        browser = nil
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    func retry() {
        stop()
        startSearching()
    }

    // MARK: - Private

    private func handleBrowserState(_ newState: NWBrowser.State) {
        switch newState {
        case .failed:
            state = .timeout
            stop()
        default:
            break
        }
    }

    private func handleResults(_ results: Set<NWBrowser.Result>) {
        guard let result = results.first else { return }

        switch result.endpoint {
        case .service(let name, _, _, _):
            // Resolve the endpoint to get host and port
            resolveEndpoint(result.endpoint, name: name)
        default:
            break
        }
    }

    private func resolveEndpoint(_ endpoint: NWEndpoint, name: String) {
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { [weak self] connState in
            DispatchQueue.main.async {
                switch connState {
                case .ready:
                    if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                       case .hostPort(let host, let port) = innerEndpoint {
                        self?.discoveredHost = "\(host)"
                        self?.discoveredPort = Int(port.rawValue)
                        self?.state = .found
                        self?.timeoutTask?.cancel()
                    }
                    connection.cancel()
                case .failed:
                    connection.cancel()
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
    }
}
