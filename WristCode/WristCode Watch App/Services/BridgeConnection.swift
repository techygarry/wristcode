import Foundation
import Combine

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case searching
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - Bridge Connection

final class BridgeConnection: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var sessions: [Session] = []
    @Published var currentMessages: [TerminalMessage] = []
    @Published var config: BridgeConfig

    private var streamTask: URLSessionDataTask?
    private var reconnectTask: Task<Void, Never>?
    private let urlSession = URLSession.shared

    private static let configKey = "wristcode.bridge.config"
    private static let tokenKey = "wristcode.bridge.jwt"

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let saved = try? JSONDecoder().decode(BridgeConfig.self, from: data) {
            self.config = saved
        } else {
            self.config = BridgeConfig()
        }
        // Restore JWT token
        config.jwtToken = UserDefaults.standard.string(forKey: Self.tokenKey)

        // Auto-connect on launch
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await autoConnect()
        }
    }

    // Tunnel URL for remote access
    private static let tunnelHost = "respiratory-ppm-hardcover-gym.trycloudflare.com"

    @MainActor
    private func autoConnect() async {
        connectionState = .connecting

        // Try localhost first (on same WiFi)
        config.host = "localhost"
        config.port = 3847
        do {
            let _: HealthResponse = try await request("GET", path: "/health")
            connectionState = .connected
            try await pair(code: "123456")
            await fetchSessions()
            return
        } catch {
            // Localhost failed, try tunnel
        }

        // Try cloudflare tunnel (remote/mobile)
        config.host = Self.tunnelHost
        config.port = 443
        do {
            let _: HealthResponse = try await request("GET", path: "/health")
            connectionState = .connected
            try await pair(code: "123456")
            await fetchSessions()
        } catch {
            connectionState = .error("Cannot reach bridge")
            scheduleReconnect()
        }
    }

    // MARK: - Computed

    private var baseURL: String {
        let host = config.tailscaleIP.isEmpty ? config.host : config.tailscaleIP
        let scheme = config.port == 443 ? "https" : "http"
        let portSuffix = config.port == 443 || config.port == 80 ? "" : ":\(config.port)"
        return "\(scheme)://\(host)\(portSuffix)/api"
    }

    // MARK: - Public Methods

    func connect() {
        guard !config.host.isEmpty || !config.tailscaleIP.isEmpty else {
            connectionState = .error("No host configured")
            return
        }
        connectionState = .connecting

        Task { @MainActor in
            do {
                let _: HealthResponse = try await request("GET", path: "/health")
                connectionState = .connected
                await fetchSessions()
            } catch {
                connectionState = .error(error.localizedDescription)
                scheduleReconnect()
            }
        }
    }

    func pair(code: String) async throws {
        struct PairRequest: Encodable { let code: String }
        struct PairResponse: Decodable { let token: String }

        let response: PairResponse = try await request(
            "POST", path: "/pair", body: PairRequest(code: code)
        )
        await MainActor.run {
            config.jwtToken = response.token
            config.pairingCode = code
            saveConfig()
        }
    }

    func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        connectionState = .disconnected
    }

    @MainActor
    func fetchSessions() async {
        do {
            struct SessionsResponse: Decodable { let sessions: [Session] }
            let response: SessionsResponse = try await request("GET", path: "/sessions")
            sessions = response.sessions
        } catch {
            sessions = []
        }
    }

    func createSession(cwd: String? = nil, model: String = "sonnet") async throws -> Session {
        struct CreateRequest: Encodable { let cwd: String?; let model: String }
        let newSession: Session = try await request(
            "POST", path: "/sessions", body: CreateRequest(cwd: cwd, model: model)
        )
        await MainActor.run {
            sessions.append(newSession)
        }
        return newSession
    }

    func deleteSession(id: String) async throws {
        let _: EmptyResponse = try await request("DELETE", path: "/sessions/\(id)")
        await MainActor.run {
            sessions.removeAll { $0.id == id }
        }
    }

    func sendPrompt(sessionId: String, prompt: String) async throws {
        struct PromptRequest: Encodable {
            let text: String
            let type: String
        }

        // Build request manually to handle response parsing carefully
        guard let url = URL(string: "\(baseURL)/sessions/\(sessionId)/prompt") else {
            throw BridgeError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 180
        if let token = config.jwtToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(PromptRequest(text: prompt, type: "text"))

        let (data, response) = try await urlSession.data(for: urlRequest)

        // Handle 401 - re-pair and retry
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            try await pair(code: "123456")
            urlRequest.setValue("Bearer \(config.jwtToken ?? "")", forHTTPHeaderField: "Authorization")
            let (retryData, _) = try await urlSession.data(for: urlRequest)
            await parsePromptResponse(retryData)
            return
        }

        await parsePromptResponse(data)
    }

    @Published var lastHasPreview: Bool = false

    @MainActor
    private func parsePromptResponse(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }

        if let jsonData = text.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {

            // Check if preview is available
            lastHasPreview = dict["hasPreview"] as? Bool ?? false

            if let response = dict["response"] as? String, !response.isEmpty {
                currentMessages.append(
                    TerminalMessage(type: .assistantText, content: response)
                )
            }
            if let cost = dict["cost"] as? [String: Any],
               let input = cost["inputTokens"] as? Int,
               let output = cost["outputTokens"] as? Int,
               let total = cost["totalCost"] as? Double {
                currentMessages.append(
                    TerminalMessage(type: .cost(input: input, output: output, cost: total), content: "")
                )
            }
            if let status = dict["status"] as? String, status == "error" {
                if let response = dict["response"] as? String {
                    currentMessages.append(
                        TerminalMessage(type: .error, content: response)
                    )
                }
            }
        } else {
            // Raw text fallback
            currentMessages.append(
                TerminalMessage(type: .assistantText, content: text)
            )
        }
    }

    func sendCommand(sessionId: String, command: String) async throws -> String {
        struct CommandRequest: Encodable { let command: String }
        struct CommandResponse: Decodable { let result: String }
        let response: CommandResponse = try await request(
            "POST",
            path: "/sessions/\(sessionId)/command",
            body: CommandRequest(command: command)
        )
        await MainActor.run {
            currentMessages.append(
                TerminalMessage(type: .userPrompt, content: command)
            )
            currentMessages.append(
                TerminalMessage(type: .assistantText, content: response.result)
            )
        }
        return response.result
    }

    func sendApproval(sessionId: String, approved: Bool) async throws {
        struct ApprovalRequest: Encodable {
            let toolUseId: String
            let decision: String
        }
        let _: EmptyResponse = try await request(
            "POST",
            path: "/sessions/\(sessionId)/approve",
            body: ApprovalRequest(toolUseId: "latest", decision: approved ? "approve" : "reject")
        )
    }

    func connectStream(sessionId: String) {
        streamTask?.cancel()

        guard let url = URL(string: "\(baseURL)/sessions/\(sessionId)/stream") else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = .infinity
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = config.jwtToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Use async bytes for true SSE streaming
        Task { [weak self] in
            do {
                let (bytes, _) = try await URLSession.shared.bytes(for: urlRequest)
                for try await line in bytes.lines {
                    guard let self = self else { break }
                    // SSE format: "data: {...}"
                    if line.hasPrefix("data: "),
                       let jsonData = line.dropFirst(6).data(using: .utf8),
                       let event = try? JSONDecoder().decode(StreamEvent.self, from: jsonData) {
                        await MainActor.run {
                            self.handleStreamEvent(event)
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.scheduleReconnect()
                }
            }
        }
    }

    // MARK: - Private Networking

    private func request<T: Decodable>(_ method: String, path: String) async throws -> T {
        try await request(method, path: path, body: Optional<EmptyBody>.none)
    }

    private func request<T: Decodable, B: Encodable>(
        _ method: String,
        path: String,
        body: B? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw BridgeError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 180

        if let token = config.jwtToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BridgeError.invalidResponse
        }

        // Auto re-pair on 401 (token expired / server restarted)
        if httpResponse.statusCode == 401 {
            try await pair(code: "123456")
            // Retry the request with new token
            if let newToken = config.jwtToken {
                urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            }
            let (retryData, retryResponse) = try await urlSession.data(for: urlRequest)
            guard let retryHttp = retryResponse as? HTTPURLResponse,
                  (200...299).contains(retryHttp.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Auth failed"
                throw BridgeError.serverError(httpResponse.statusCode, message)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: retryData)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw BridgeError.serverError(httpResponse.statusCode, message)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Stream Event Handling

    private func handleStreamEvent(_ event: StreamEvent) {
        let p = event.payload
        let message: TerminalMessage
        switch event.type {
        case "text":
            let word = p?.word ?? p?.content ?? ""
            if !word.isEmpty {
                // Append word to last assistant message or create new
                if let last = currentMessages.last,
                   case .assistantText = last.type {
                    let updated = TerminalMessage(
                        id: last.id,
                        type: .assistantText,
                        content: last.content + word,
                        timestamp: last.timestamp
                    )
                    currentMessages[currentMessages.count - 1] = updated
                } else {
                    currentMessages.append(
                        TerminalMessage(type: .assistantText, content: word)
                    )
                }
            }
            return
        case "tool_use":
            message = TerminalMessage(
                type: .toolUse(name: p?.toolName ?? "tool"),
                content: p?.content ?? p?.toolName ?? ""
            )
        case "tool_result":
            message = TerminalMessage(type: .toolResult, content: p?.output ?? p?.content ?? "")
        case "approval_request":
            message = TerminalMessage(type: .assistantText, content: p?.summary ?? "Approval needed")
        case "error":
            message = TerminalMessage(type: .error, content: p?.content ?? "Unknown error")
        case "cost":
            if let input = p?.inputTokens, let output = p?.outputTokens, let cost = p?.totalCost {
                message = TerminalMessage(type: .cost(input: input, output: output, cost: cost), content: "")
            } else {
                return
            }
        case "status", "ping":
            return
        default:
            return
        }
        currentMessages.append(message)
    }

    // MARK: - Reconnect

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            self?.connect()
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
        if let token = config.jwtToken {
            UserDefaults.standard.set(token, forKey: Self.tokenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        }
    }
}

// MARK: - Supporting Types

private struct HealthResponse: Decodable {
    let status: String
}

private struct EmptyResponse: Decodable {}
private struct EmptyBody: Encodable {}

private struct StreamEvent: Decodable {
    let type: String
    let payload: StreamPayload?
    let timestamp: String?

    struct StreamPayload: Decodable {
        let content: String?
        let state: String?
        let toolName: String?
        let toolInput: [String: String]?
        let output: String?
        let isError: Bool?
        let summary: String?
        let word: String?
        let progress: Double?
        let inputTokens: Int?
        let outputTokens: Int?
        let totalCost: Double?
    }
}

// MARK: - Bridge Error

enum BridgeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        }
    }
}
