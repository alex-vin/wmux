import Foundation
import WebKit

/// Reply-capable transport for diff viewer. Each request is handled by native Swift
/// and git Process operations. WebKit never receives filesystem paths or process access.
@MainActor
final class DiffSidecarBridge: NSObject, WKScriptMessageHandlerWithReply {
    static let handlerName = "cmuxDiff"
    static let shared = DiffSidecarBridge()

    private static var handlerInstalledKey: UInt8 = 0
    private static let maximumRequestBytes = 1024 * 1024
    private nonisolated static let maximumResponseBytes = 32 * 1024 * 1024
    private nonisolated static let processPool = DiffSidecarProcessPool(limit: 4)
    private static let pendingSessionID = "00000000-0000-0000-0000-000000000000"
    private struct ViewerInvocationKey: Hashable {
        let webView: ObjectIdentifier
        let token: String
    }
    private var invocations: [UUID: Task<Void, Never>] = [:]
    private var sessionInvocationByViewer: [ViewerInvocationKey: UUID] = [:]
    private var discardedSessionInvocations: Set<UUID> = []

    /// Faults the Rust executable and its dynamic dependencies into the OS cache
    /// during app startup. The handshake uses stdio and exits; it never binds a
    /// port or leaves a sidecar process running.
    nonisolated static func prewarm() {
        Task.detached(priority: .utility) {
            let request = Data(#"{"id":"prewarm","version":1,"method":"protocolHandshake"}"#.utf8)
            _ = try? await processPool.run(request: request)
        }
    }

    static func installIfNeeded(on userContentController: WKUserContentController) {
        guard objc_getAssociatedObject(userContentController, &handlerInstalledKey) == nil else {
            return
        }
        userContentController.addScriptMessageHandler(
            shared,
            contentWorld: .page,
            name: handlerName
        )
        objc_setAssociatedObject(
            userContentController,
            &handlerInstalledKey,
            NSNumber(value: true),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    static func installViewerBridges(on userContentController: WKUserContentController) {
        DiffCommentsBridge.installIfNeeded(on: userContentController)
        installIfNeeded(on: userContentController)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        guard Self.isTrustedSidecarFrame(message.frameInfo),
              JSONSerialization.isValidJSONObject(message.body),
              let body = message.body as? [String: Any] else {
            replyHandler(Self.failureResponse(body: message.body, code: "notAllowed", message: "Diff sidecar request was rejected"), nil)
            return
        }

        let invocationID = UUID()
        let method = body["method"] as? String
        var sidecarBody = body
        var discardedSessionCloseRequest: Data?
        if method == "sessionOpen",
           var params = body["params"] as? [String: Any],
           let capabilityToken = params["capabilityToken"] as? String {
            let sessionID = UUID().uuidString
            params["sessionId"] = sessionID
            sidecarBody["params"] = params
            discardedSessionCloseRequest = Self.sessionCloseRequest(
                capabilityToken: capabilityToken,
                sessionID: sessionID
            )
        }
        guard let request = try? JSONSerialization.data(withJSONObject: sidecarBody),
              request.count <= Self.maximumRequestBytes else {
            replyHandler(Self.failureResponse(body: message.body, code: "notAllowed", message: "Diff sidecar request was rejected"), nil)
            return
        }
        let viewerToken = DiffCommentsBridge.diffViewerToken(from: message.frameInfo.request.url)
        let viewerKey = message.webView.flatMap { webView in
            viewerToken.map { ViewerInvocationKey(webView: ObjectIdentifier(webView), token: $0) }
        }
        let closeSessionID = ((message.body as? [String: Any])?["params"] as? [String: Any])?["sessionId"] as? String
        if method == "sessionClose",
           closeSessionID == Self.pendingSessionID {
            if let viewerKey, let pendingID = sessionInvocationByViewer[viewerKey] {
                discardedSessionInvocations.insert(pendingID)
                invocations[pendingID]?.cancel()
            }
            replyHandler([
                "id": (message.body as? [String: Any])?["id"] as? String ?? "unknown",
                "version": 1,
                "result": ["type": "sessionClosed"],
                "error": NSNull(),
            ], nil)
            return
        }
        if method == "sessionOpen", let viewerKey,
           let previousID = sessionInvocationByViewer[viewerKey] {
            discardedSessionInvocations.insert(previousID)
            invocations[previousID]?.cancel()
        }

        let task = Task { [weak self] in
            let result: Result<Data, Error>
            do {
                result = .success(try await Self.processPool.run(request: request))
            } catch {
                result = .failure(error)
            }
            guard let self else { return }
            if self.discardedSessionInvocations.remove(invocationID) != nil,
               let discardedSessionCloseRequest {
                await Self.closeDiscardedSession(request: discardedSessionCloseRequest)
            }
            switch result {
            case .success(let responseData):
                guard let response = try? JSONSerialization.jsonObject(with: responseData) else {
                    replyHandler(Self.failureResponse(body: message.body, code: "invalidResponse", message: "Diff sidecar returned invalid JSON"), nil)
                    self.finishInvocation(invocationID, viewerKey: viewerKey)
                    return
                }
                replyHandler(response, nil)
            case .failure:
                replyHandler(Self.failureResponse(body: message.body, code: "sidecarUnavailable", message: "Diff sidecar is unavailable"), nil)
            }
            self.finishInvocation(invocationID, viewerKey: viewerKey)
        }
        invocations[invocationID] = task
        if method == "sessionOpen", let viewerKey {
            sessionInvocationByViewer[viewerKey] = invocationID
        }
    }

    private func finishInvocation(_ invocationID: UUID, viewerKey: ViewerInvocationKey?) {
        invocations.removeValue(forKey: invocationID)
        discardedSessionInvocations.remove(invocationID)
        if let viewerKey, sessionInvocationByViewer[viewerKey] == invocationID {
            sessionInvocationByViewer.removeValue(forKey: viewerKey)
        }
    }

    nonisolated private static func sessionCloseRequest(
        capabilityToken: String,
        sessionID: String
    ) -> Data? {
        let close: [String: Any] = [
            "id": UUID().uuidString,
            "version": 1,
            "method": "sessionClose",
            "params": [
                "capabilityToken": capabilityToken,
                "sessionId": sessionID,
            ],
        ]
        return try? JSONSerialization.data(withJSONObject: close)
    }

    nonisolated private static func closeDiscardedSession(request: Data) async {
        await Task.detached(priority: .utility) {
            _ = try? await processPool.run(request: request)
        }.value
    }

    static func isTrustedSidecarFrame(_ frameInfo: WKFrameInfo) -> Bool {
        frameInfo.isMainFrame && isTrustedSidecarURL(frameInfo.request.url)
    }

    static func isTrustedSidecarURL(_ url: URL?) -> Bool {
        guard let url else { return false }
        return CmuxDiffViewerURLSchemeHandler.shared.allowsNavigation(to: url)
    }

    #if compiler(>=6.2)
    @concurrent
    #else
    @Sendable
    #endif
    nonisolated fileprivate static func runSidecar(request: Data) async throws -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: request) as? [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let id = json["id"] as? String ?? UUID().uuidString
        let method = json["method"] as? String ?? ""
        let params = json["params"] as? [String: Any] ?? [:]

        switch method {
        case "protocolHandshake":
            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": [
                    "type": "handshake",
                    "value": [
                        "protocolVersion": 1,
                        "capabilities": ["resource.stream", "transport.webkit", "transport.stdio"]
                    ]
                ],
                "error": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: response)

        case "sessionClose":
            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": [
                    "type": "sessionClosed"
                ],
                "error": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: response)

        case "sessionOpen":
            let capabilityToken = params["capabilityToken"] as? String ?? ""
            let sessionID = params["sessionId"] as? String ?? UUID().uuidString
            let source = params["source"] as? [String: Any] ?? [:]
            let kind = source["kind"] as? String ?? "unstaged"
            let repoRoot = source["repoRoot"] as? String ?? FileManager.default.currentDirectoryPath

            var gitArgs = ["-C", repoRoot, "diff", "--no-color"]
            if kind == "staged" {
                gitArgs = ["-C", repoRoot, "diff", "--cached", "--no-color"]
            } else if kind == "branch" {
                let baseRef = source["baseRef"] as? String ?? "HEAD"
                gitArgs = ["-C", repoRoot, "diff", "\(baseRef)...HEAD", "--no-color"]
            }

            let root = try prepareRootDirectory()
            let fileName = "diff-session-\(sessionID).patch"
            let patchURL = root.appendingPathComponent(fileName)

            let diffData: Data
            if kind == "patch", let patchSourcePath = source["path"] as? String {
                diffData = (try? Data(contentsOf: URL(fileURLWithPath: patchSourcePath))) ?? Data()
            } else {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = gitArgs
                let stdout = Pipe()
                process.standardOutput = stdout
                process.standardError = Pipe()
                try process.run()
                diffData = stdout.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
            }

            try diffData.write(to: patchURL)

            if !capabilityToken.isEmpty {
                let manifestURL = root.appendingPathComponent(".manifest-\(capabilityToken).json")
                var manifestFiles: [[String: Any]] = []
                if let existingData = try? Data(contentsOf: manifestURL),
                   let existingJson = try? JSONSerialization.jsonObject(with: existingData) as? [String: Any],
                   let existingFiles = existingJson["files"] as? [[String: Any]] {
                    manifestFiles = existingFiles
                }
                manifestFiles.append([
                    "request_path": "/\(fileName)",
                    "file_path": patchURL.path,
                    "mime_type": "text/x-diff",
                    "remote_url": NSNull()
                ])
                let manifestObject: [String: Any] = [
                    "token": capabilityToken,
                    "files": manifestFiles
                ]
                if let encoded = try? JSONSerialization.data(withJSONObject: manifestObject, options: [.sortedKeys]) {
                    try? encoded.write(to: manifestURL)
                }
            }

            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": [
                    "type": "sessionOpened",
                    "value": [
                        "sessionId": sessionID,
                        "patch": [
                            "id": "cmux-diff-viewer://\(capabilityToken)/\(fileName)",
                            "mediaType": "text/x-diff",
                            "byteLength": diffData.count,
                            "revision": 1
                        ],
                        "source": source,
                        "generatedPaths": []
                    ]
                ],
                "error": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: response)

        case "branchList":
            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": [
                    "type": "branches",
                    "value": [
                        "groups": []
                    ]
                ],
                "error": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: response)

        case "branchChange":
            let capabilityToken = params["capabilityToken"] as? String ?? ""
            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": [
                    "type": "navigation",
                    "value": [
                        "url": "cmux-diff-viewer://\(capabilityToken)/generated.html"
                    ]
                ],
                "error": NSNull()
            ]
            return try JSONSerialization.data(withJSONObject: response)

        default:
            let response: [String: Any] = [
                "id": id,
                "version": 1,
                "result": NSNull(),
                "error": ["code": "unsupportedMethod", "message": "Method not supported"]
            ]
            return try JSONSerialization.data(withJSONObject: response)
        }
    }

    nonisolated private static func prepareRootDirectory() throws -> URL {
        let root = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appendingPathComponent("cmux-diff-viewer-\(Darwin.getuid())", isDirectory: true)
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: root.path)
        return root
    }

    private static func failureResponse(body: Any, code: String, message: String) -> [String: Any] {
        let request = body as? [String: Any]
        return [
            "id": request?["id"] as? String ?? "unknown",
            "version": request?["version"] as? Int ?? 1,
            "result": NSNull(),
            "error": ["code": code, "message": message],
        ]
    }
}

actor DiffSidecarProcessPool {
    private enum PoolError: Error { case queueFull }
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Bool, Never>
    }

    private let limit: Int
    private let queueLimit = 32
    private var activeCount = 0
    private var waiters: [Waiter] = []

    init(limit: Int) {
        precondition(limit > 0)
        self.limit = limit
    }

    func run(request: Data) async throws -> Data {
        try await withPermit {
            try await DiffSidecarBridge.runSidecar(request: request)
        }
    }

    func withPermit<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        try await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async throws {
        try Task.checkCancellation()
        if activeCount < limit {
            activeCount += 1
            return
        }
        guard waiters.count < queueLimit else { throw PoolError.queueFull }

        let waiterID = UUID()
        let granted = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                waiters.append(Waiter(id: waiterID, continuation: continuation))
            }
        } onCancel: {
            Task { await self.cancelWaiter(waiterID) }
        }
        guard granted else {
            throw CancellationError()
        }
        if Task.isCancelled {
            release()
            throw CancellationError()
        }
    }

    private func cancelWaiter(_ waiterID: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == waiterID }) else { return }
        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(returning: false)
    }

    private func release() {
        if waiters.isEmpty {
            activeCount -= 1
            return
        }
        let waiter = waiters.removeFirst()
        waiter.continuation.resume(returning: true)
    }
}
