import Foundation
import Observation

/// Status indicator color semantics for Gemini quota.
public enum GeminiQuotaHealthStatus: Sendable, Equatable {
    case healthy
    case warning
    case critical
    case disabled
}

/// `@MainActor @Observable` store managing Gemini accounts, persistence, and quota refreshes.
@MainActor
@Observable
public final class GeminiAccountStore {
    /// List of registered Google accounts.
    public private(set) var accounts: [GeminiAccount] = []
    /// The globally active or default account ID.
    public var defaultAccountID: String?
    /// Whether a quota refresh is currently in progress.
    public private(set) var isRefreshing: Bool = false
    /// Last error encountered during account operations.
    public private(set) var lastErrorMessage: String?

    private let storageURL: URL
    private let oAuthService: GeminiOAuthService
    private let quotaService: GeminiQuotaService
    private let callbackServer: GeminiOAuthCallbackServer

    /// Default configuration directory for cmux gemini storage.
    public static var defaultStorageURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/cmux/gemini_accounts.json")
    }

    /// Creates an account store with injected dependencies.
    ///
    /// - Parameters:
    ///   - storageURL: Path to the JSON persistence file.
    ///   - oAuthService: OAuth client service.
    ///   - quotaService: Quota retrieval service.
    ///   - callbackServer: Loopback OAuth server.
    public init(
        storageURL: URL = GeminiAccountStore.defaultStorageURL,
        oAuthService: GeminiOAuthService = GeminiOAuthService(),
        quotaService: GeminiQuotaService = GeminiQuotaService(),
        callbackServer: GeminiOAuthCallbackServer = GeminiOAuthCallbackServer()
    ) {
        self.storageURL = storageURL
        self.oAuthService = oAuthService
        self.quotaService = quotaService
        self.callbackServer = callbackServer
        loadFromDisk()
    }

    /// Returns the account by ID.
    public func account(for id: String) -> GeminiAccount? {
        accounts.first { $0.id == id }
    }

    /// The resolved default account.
    public var defaultAccount: GeminiAccount? {
        if let defaultAccountID, let acc = account(for: defaultAccountID) {
            return acc
        }
        return accounts.first
    }

    /// Adds or updates an account and saves to disk.
    public func addOrUpdateAccount(_ account: GeminiAccount) {
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
        } else {
            accounts.append(account)
        }
        if defaultAccountID == nil {
            defaultAccountID = account.id
        }
        saveToDisk()
    }

    /// Removes an account by ID and saves to disk.
    public func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
        if defaultAccountID == id {
            defaultAccountID = accounts.first?.id
        }
        saveToDisk()
    }

    /// Evaluates health status for a given account.
    public func healthStatus(for account: GeminiAccount) -> GeminiQuotaHealthStatus {
        guard !account.isDisabled else { return .disabled }
        guard let flagship = account.quota.flagshipModel else {
            return account.quota.isForbidden ? .critical : .healthy
        }
        let fiveHourPct = account.quota.bucket5h(for: flagship)?.remainingPercentage ?? flagship.percentage
        if fiveHourPct <= 20 {
            return .critical
        } else if fiveHourPct <= 50 {
            return .warning
        }
        return .healthy
    }

    /// Initiates Google OAuth login in browser and handles local loopback callback.
    ///
    /// - Returns: Newly authenticated ``GeminiAccount``.
    public func startOAuthLogin() async throws -> GeminiAccount {
        let state = UUID().uuidString
        let callbackTask = Task {
            try await callbackServer.start(state: state)
        }

        // Give the listener a moment to bind
        try await Task.sleep(nanoseconds: 50_000_000)

        // Generate auth URL
        // Temporary dummy port, will be overridden once callback task starts
        let (redirectURI, code) = try await callbackTask.value
        guard let authURL = await oAuthService.authorizationURL(redirectURI: redirectURI, state: state) else {
            throw URLError(.badURL)
        }

        // Open in browser
        _ = await Task { @MainActor in
            NSWorkspace.shared.open(authURL)
        }.value

        let tokenData = try await oAuthService.exchangeCode(code, redirectURI: redirectURI)
        guard let accessToken = tokenData["access_token"] as? String else {
            throw URLError(.userAuthenticationRequired)
        }

        let refreshToken = tokenData["refresh_token"] as? String
        let idToken = tokenData["id_token"] as? String
        let expiresIn = (tokenData["expires_in"] as? NSNumber)?.doubleValue ?? 3600.0
        let expiry = Date().timeIntervalSince1970 + expiresIn

        let (email, name) = try await oAuthService.fetchUserInfo(accessToken: accessToken)

        var newAccount = GeminiAccount(
            id: email,
            email: email,
            name: name,
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            expiryTimestamp: expiry
        )

        // Fetch initial quota
        do {
            newAccount = try await quotaService.refreshQuota(for: newAccount)
        } catch {
            // best-effort
        }

        addOrUpdateAccount(newAccount)
        defaultAccountID = newAccount.id
        return newAccount
    }

    /// Refreshes all non-disabled accounts concurrently.
    public func refreshAllAccounts() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: GeminiAccount?.self) { group in
            for account in accounts where !account.isDisabled {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return await self.performRefresh(account: account)
                }
            }

            for await result in group {
                if let updated = result {
                    if let idx = accounts.firstIndex(where: { $0.id == updated.id }) {
                        accounts[idx] = updated
                    }
                }
            }
        }

        saveToDisk()
    }

    /// Refreshes a single account by ID.
    public func refreshAccount(id: String) async {
        guard let acc = account(for: id) else { return }
        if let updated = await performRefresh(account: acc) {
            addOrUpdateAccount(updated)
        }
    }

    private func performRefresh(account: GeminiAccount) async -> GeminiAccount? {
        var acc = account
        // 1. Refresh token if needed
        if acc.needsTokenRefresh(), let rt = acc.refreshToken {
            do {
                let tokenData = try await oAuthService.refreshAccessToken(refreshToken: rt)
                if let newAccess = tokenData["access_token"] as? String {
                    acc.accessToken = newAccess
                    let expiresIn = (tokenData["expires_in"] as? NSNumber)?.doubleValue ?? 3600.0
                    acc.expiryTimestamp = Date().timeIntervalSince1970 + expiresIn
                }
            } catch {
                let desc = error.localizedDescription
                if desc.contains("invalid_grant") {
                    acc.isDisabled = true
                    acc.disabledReason = "invalid_grant: 账号授权已失效，请重新登录"
                    return acc
                }
            }
        }

        // 2. Refresh quota
        do {
            return try await quotaService.refreshQuota(for: acc)
        } catch {
            return acc
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode(GeminiStoragePayload.self, from: data)
            self.accounts = decoded.accounts
            self.defaultAccountID = decoded.defaultAccountID
        } catch {
            // Silently ignore or initialize empty
        }
    }

    private func saveToDisk() {
        let parentDir = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        let payload = GeminiStoragePayload(accounts: accounts, defaultAccountID: defaultAccountID)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(payload) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }
}

private struct GeminiStoragePayload: Codable {
    let accounts: [GeminiAccount]
    let defaultAccountID: String?
}
