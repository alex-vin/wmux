import Foundation
import Network

/// Lightweight loopback HTTP server using Network.framework to handle Google OAuth 2.0 callbacks.
public actor GeminiOAuthCallbackServer {
    private var listener: NWListener?
    private var continuation: CheckedContinuation<String, any Error>?
    private var expectedState: String?

    /// Creates a callback server.
    public init() {}

    /// Starts listening on an ephemeral loopback port and waits for the OAuth code callback.
    ///
    /// - Parameters:
    ///   - state: Random state string to validate against CSRF.
    ///   - timeoutSeconds: Maximum seconds to wait before cancelling (default: 120s).
    /// - Returns: Tuple of (redirectURI, code).
    public func start(state: String, timeoutSeconds: TimeInterval = 120.0) async throws -> (redirectURI: String, code: String) {
        self.expectedState = state

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = false
        // Bind to localhost IPv4
        guard let localAddr = IPv4Address("127.0.0.1") else {
            throw URLError(.cannotConnectToHost)
        }
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(localAddr), port: .any)

        let listener = try NWListener(using: params)
        self.listener = listener

        let portPromise = Task<UInt16, any Error> {
            try await withCheckedThrowingContinuation { (portCont: CheckedContinuation<UInt16, any Error>) in
                listener.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        if let port = listener.port?.rawValue {
                            portCont.resume(returning: port)
                        } else {
                            portCont.resume(throwing: URLError(.cannotFindHost))
                        }
                    case .failed(let err):
                        portCont.resume(throwing: err)
                    default:
                        break
                    }
                }
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            Task {
                await self.handleConnection(connection)
            }
        }

        listener.start(queue: .global())
        let port = try await portPromise.value
        let redirectURI = "http://127.0.0.1:\(port)/oauth2callback"

        let code = try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (codeCont: CheckedContinuation<String, any Error>) in
                    Task { [weak self] in
                        guard let self else { return }
                        await self.setContinuation(codeCont)
                    }
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                throw URLError(.timedOut)
            }

            let firstResult = try await group.next()!
            group.cancelAll()
            return firstResult
        }

        stop()
        return (redirectURI, code)
    }

    /// Stops the server.
    public func stop() {
        listener?.cancel()
        listener = nil
        continuation = nil
        expectedState = nil
    }

    private func setContinuation(_ cont: CheckedContinuation<String, any Error>) {
        self.continuation = cont
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, err in
            guard let self, let data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            Task {
                await self.processRequest(request, connection: connection)
            }
        }
    }

    private func processRequest(_ request: String, connection: NWConnection) {
        // Parse GET /oauth2callback?code=...&state=...
        guard let firstLine = request.split(separator: "\r\n").first,
              let urlPart = firstLine.split(separator: " ").dropFirst().first,
              let components = URLComponents(string: String(urlPart)),
              components.path == "/oauth2callback" else {
            sendResponse(connection: connection, statusCode: 404, html: "Not Found")
            return
        }

        let queryItems = components.queryItems ?? []
        let state = queryItems.first(where: { $0.name == "state" })?.value
        let code = queryItems.first(where: { $0.name == "code" })?.value
        let error = queryItems.first(where: { $0.name == "error" })?.value

        if let error {
            sendResponse(connection: connection, statusCode: 400, html: "<h3>授权失败</h3><p>\(error)</p>")
            continuation?.resume(throwing: NSError(domain: "GeminiOAuthCallbackServer", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
            continuation = nil
            return
        }

        guard let state, state == expectedState, let code else {
            sendResponse(connection: connection, statusCode: 400, html: "<h3>授权状态校验失败 (CSRF)</h3>")
            continuation?.resume(throwing: URLError(.userAuthenticationRequired))
            continuation = nil
            return
        }

        let successHtml = """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><title>wmux 授权成功</title></head>
        <body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;text-align:center;padding:60px 20px;background:#1e1e24;color:#e0e0e0;">
            <div style="max-width:400px;margin:0 auto;background:#2b2b36;padding:30px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.3);">
                <div style="font-size:48px;margin-bottom:16px;">✨</div>
                <h2 style="margin:0 0 10px 0;color:#fff;">授权成功</h2>
                <p style="color:#aaa;font-size:14px;line-height:1.5;">已成功连接 Google 账号，请返回 <strong>wmux</strong> 继续使用。</p>
            </div>
            <script>setTimeout(function(){ window.close(); }, 3000);</script>
        </body>
        </html>
        """
        sendResponse(connection: connection, statusCode: 200, html: successHtml)
        continuation?.resume(returning: code)
        continuation = nil
    }

    private func sendResponse(connection: NWConnection, statusCode: Int, html: String) {
        let response = "HTTP/1.1 \(statusCode) OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
        connection.send(content: Data(response.utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
