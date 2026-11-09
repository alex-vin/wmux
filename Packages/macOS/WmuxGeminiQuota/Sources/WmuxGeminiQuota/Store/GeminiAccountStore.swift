import AppKit
public import Foundation
public import Observation
import os.log

private let logger = Logger(subsystem: "com.wmux.gemini", category: "AccountStore")

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
    public var defaultAccountID: String? {
        didSet {
            if defaultAccountID != oldValue {
                saveToDisk()
            }
        }
    }
    /// Whether a quota refresh is currently in progress.
    public private(set) var isRefreshing: Bool = false
    /// Last error encountered during account operations.
    public private(set) var lastErrorMessage: String?

    private let storageURL: URL
    private let oAuthService: GeminiOAuthService
    private let quotaService: GeminiQuotaService
    private let callbackServer: GeminiOAuthCallbackServer

    /// Canonical authoritative configuration storage file for wmux gemini accounts.
    public static var canonicalStorageURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/wmux/gemini_accounts.json")
    }

    /// Legacy configuration storage file for cmux gemini accounts.
    public static var legacyStorageURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/cmux/gemini_accounts.json")
    }

    /// Default configuration storage file for wmux/cmux gemini accounts.
    /// Automatically performs seamless migration from cmux to wmux if wmux does not exist yet.
    public static var defaultStorageURL: URL {
        migrateLegacyStorageIfNeeded()
        return canonicalStorageURL
    }

    /// Seamlessly migrates existing accounts from ~/.config/cmux/gemini_accounts.json
    /// to ~/.config/wmux/gemini_accounts.json if the wmux destination does not exist yet.
    @discardableResult
    public static func migrateLegacyStorageIfNeeded() -> Bool {
        let fm = FileManager.default
        let wmuxURL = canonicalStorageURL
        let cmuxURL = legacyStorageURL

        guard !fm.fileExists(atPath: wmuxURL.path),
              fm.fileExists(atPath: cmuxURL.path) else {
            return false
        }

        do {
            let parentDir = wmuxURL.deletingLastPathComponent()
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
            try fm.copyItem(at: cmuxURL, to: wmuxURL)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: wmuxURL.path)
            logger.info("Successfully migrated Gemini accounts from cmux to canonical wmux storage: \(wmuxURL.path)")
            return true
        } catch {
            logger.error("Failed to migrate Gemini accounts from \(cmuxURL.path) to \(wmuxURL.path): \(error.localizedDescription)")
            return false
        }
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

    /// Sets an account as the global default, persists it, and syncs to host credential store.
    public func setDefaultAccount(id: String) {
        guard let account = account(for: id) else { return }
        defaultAccountID = id
        saveToDisk()
        syncDefaultAccountCredentials(account)
    }

    /// Syncs the given account's credentials to the host user keychain and ~/.gemini/google_accounts.json.
    public func syncDefaultAccountCredentials(_ account: GeminiAccount) {
        let secret = account.agyKeyringSecretValue()
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let hostKeychain = home.appendingPathComponent("Library/Keychains/login.keychain-db")
        if fm.fileExists(atPath: hostKeychain.path) {
            let p1 = Process()
            p1.executableURL = URL(fileURLWithPath: "/usr/bin/security")
            p1.arguments = ["delete-generic-password", "-s", "gemini", "-a", "antigravity", hostKeychain.path]
            try? p1.run()
            p1.waitUntilExit()

            let p2 = Process()
            p2.executableURL = URL(fileURLWithPath: "/usr/bin/security")
            p2.arguments = ["add-generic-password", "-s", "gemini", "-a", "antigravity", "-w", secret, "-A", hostKeychain.path]
            try? p2.run()
            p2.waitUntilExit()
        }

        let googleAccountsURL = home.appendingPathComponent(".gemini/google_accounts.json")
        if fm.fileExists(atPath: googleAccountsURL.path) {
            if var obj = (try? JSONSerialization.jsonObject(with: Data(contentsOf: googleAccountsURL))) as? [String: Any] {
                obj["active"] = account.email
                if let updated = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]) {
                    try? updated.write(to: googleAccountsURL)
                }
            }
        }

        let jetskiTokenURL = home.appendingPathComponent(".gemini/jetski-standalone-oauth-token")
        let payloadJSON = account.agyPayloadJSON()
        if let data = payloadJSON.data(using: .utf8) {
            let geminiDir = jetskiTokenURL.deletingLastPathComponent()
            try? fm.createDirectory(at: geminiDir, withIntermediateDirectories: true)
            try? data.write(to: jetskiTokenURL, options: .atomic)
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: jetskiTokenURL.path)
        }
    }

    /// Evaluates health status for a given account.
    public func healthStatus(for account: GeminiAccount) -> GeminiQuotaHealthStatus {
        guard !account.isDisabled else { return .disabled }
        if account.quota.isForbidden || account.quota.isRateLimited {
            return .critical
        }
        guard let flagship = account.quota.flagshipModel else {
            return .healthy
        }
        let fiveHourPct = account.quota.bucket5h(for: flagship)?.remainingPercentage ?? flagship.percentage
        let weeklyPct = account.quota.bucketWeekly(for: flagship)?.remainingPercentage ?? 100
        let minPct = min(fiveHourPct, weeklyPct)
        if minPct <= 20 {
            return .critical
        } else if minPct <= 50 {
            return .warning
        }
        return .healthy
    }

    /// Initiates Google OAuth login in browser and handles local loopback callback.
    ///
    /// - Returns: Newly authenticated ``GeminiAccount``.
    public func startOAuthLogin() async throws -> GeminiAccount {
        let state = UUID().uuidString
        let redirectURI = try await callbackServer.start(state: state)

        guard let authURL = oAuthService.authorizationURL(redirectURI: redirectURI, state: state) else {
            await callbackServer.stop()
            throw URLError(.badURL)
        }

        // Open in browser
        NSWorkspace.shared.open(authURL)

        // Wait for callback code
        let code = try await callbackServer.waitForCode()

        let tokenResponse = try await oAuthService.exchangeCode(code, redirectURI: redirectURI)
        guard !tokenResponse.accessToken.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let accessToken = tokenResponse.accessToken
        let refreshToken = tokenResponse.refreshToken
        let idToken = tokenResponse.idToken
        let expiresIn = tokenResponse.expiresIn ?? 3600.0
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
        setDefaultAccount(id: newAccount.id)
        return newAccount
    }

    /// Performs a background credential self-healing check on startup.
    ///
    /// Verifies keychain and local credentials for the default active account,
    /// refreshes expired/expiring access tokens, and resyncs them.
    public func performStartupSelfHealing() {
        guard let activeAccount = defaultAccount, !activeAccount.isDisabled else {
            return
        }

        // 1. Immediately ensure credentials are up-to-date in keychain and ~/.gemini/
        syncDefaultAccountCredentials(activeAccount)

        // 2. If token is near expiration or expired, trigger background refresh and re-sync
        if activeAccount.needsTokenRefresh() && activeAccount.refreshToken != nil {
            Task { [weak self] in
                guard let self else { return }
                await self.refreshAccount(id: activeAccount.id)
                if let refreshed = self.account(for: activeAccount.id), !refreshed.isDisabled {
                    self.syncDefaultAccountCredentials(refreshed)
                }
            }
        }
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
                let tokenResponse = try await oAuthService.refreshAccessToken(refreshToken: rt)
                acc.accessToken = tokenResponse.accessToken
                if let newRefreshToken = tokenResponse.refreshToken {
                    acc.refreshToken = newRefreshToken
                }
                if let newIdToken = tokenResponse.idToken {
                    acc.idToken = newIdToken
                }
                let expiresIn = tokenResponse.expiresIn ?? 3600.0
                acc.expiryTimestamp = Date().timeIntervalSince1970 + expiresIn
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
        let fm = FileManager.default
        if !fm.fileExists(atPath: storageURL.path) && storageURL == Self.canonicalStorageURL {
            Self.migrateLegacyStorageIfNeeded()
        }

        guard fm.fileExists(atPath: storageURL.path) else { return }
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)

        guard let data = try? Data(contentsOf: storageURL), !data.isEmpty else { return }

        // Strategy 1: Standard GeminiStoragePayload decode
        do {
            let decoded = try JSONDecoder().decode(GeminiStoragePayload.self, from: data)
            if !decoded.accounts.isEmpty {
                self.accounts = decoded.accounts
                self.defaultAccountID = decoded.defaultAccountID ?? decoded.accounts.first?.id
                return
            }
        } catch {
            let errorMsg = "Failed to decode GeminiStoragePayload from \(storageURL.path): \(error)"
            self.lastErrorMessage = errorMsg
            logger.error("\(errorMsg)")
        }

        // Backup corrupted file to avoid accidental data loss before attempting recovery
        backupCorruptedFile(data: data)

        // Strategy 2: Attempt raw [GeminiAccount] array decode
        if let rawAccounts = try? JSONDecoder().decode([GeminiAccount].self, from: data), !rawAccounts.isEmpty {
            logger.info("Recovered \(rawAccounts.count) accounts from array format")
            self.accounts = rawAccounts
            self.defaultAccountID = rawAccounts.first?.id
            saveToDisk()
            return
        }

        // Strategy 3: Tolerant element-by-element recovery
        if let recoveredAccounts = recoverAccountsTolerantly(from: data), !recoveredAccounts.isEmpty {
            logger.info("Tolerantly recovered \(recoveredAccounts.count) accounts from damaged payload")
            self.accounts = recoveredAccounts
            self.defaultAccountID = recoveredAccounts.first?.id
            saveToDisk()
            return
        }

        // Strategy 4: Fallback to legacy cmux storage if wmux was empty or unrecoverable
        if storageURL == Self.canonicalStorageURL && fm.fileExists(atPath: Self.legacyStorageURL.path) {
            if let legacyData = try? Data(contentsOf: Self.legacyStorageURL),
               let legacyDecoded = try? JSONDecoder().decode(GeminiStoragePayload.self, from: legacyData),
               !legacyDecoded.accounts.isEmpty {
                logger.info("Recovered \(legacyDecoded.accounts.count) accounts from legacy cmux backup")
                self.accounts = legacyDecoded.accounts
                self.defaultAccountID = legacyDecoded.defaultAccountID ?? legacyDecoded.accounts.first?.id
                saveToDisk()
                return
            }
        }
    }

    private func backupCorruptedFile(data: Data) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = storageURL.deletingPathExtension().appendingPathExtension("corrupted.\(timestamp).json")
        do {
            try data.write(to: backupURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
            logger.warning("Backed up corrupted Gemini accounts file to \(backupURL.path)")
        } catch {
            logger.error("Failed to write corrupted backup file: \(error.localizedDescription)")
        }
    }

    private func recoverAccountsTolerantly(from data: Data) -> [GeminiAccount]? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        var rawList: [Any] = []
        if let dict = jsonObject as? [String: Any] {
            if let accList = dict["accounts"] as? [Any] {
                rawList = accList
            }
        } else if let arr = jsonObject as? [Any] {
            rawList = arr
        }

        guard !rawList.isEmpty else { return nil }

        var results: [GeminiAccount] = []
        let decoder = JSONDecoder()
        for item in rawList {
            guard let dict = item as? [String: Any],
                  JSONSerialization.isValidJSONObject(dict),
                  let itemData = try? JSONSerialization.data(withJSONObject: dict) else {
                continue
            }
            if let account = try? decoder.decode(GeminiAccount.self, from: itemData) {
                results.append(account)
            }
        }
        return results.isEmpty ? nil : results
    }

    private func saveToDisk() {
        let parentDir = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        let payload = GeminiStoragePayload(accounts: accounts, defaultAccountID: defaultAccountID)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(payload) {
            try? data.write(to: storageURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
        }
    }
}

private struct GeminiStoragePayload: Codable {
    let accounts: [GeminiAccount]
    let defaultAccountID: String?

    enum CodingKeys: String, CodingKey {
        case accounts, defaultAccountID
    }

    init(accounts: [GeminiAccount], defaultAccountID: String?) {
        self.accounts = accounts
        self.defaultAccountID = defaultAccountID
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accounts = (try? container.decodeIfPresent([GeminiAccount].self, forKey: .accounts)) ?? []
        self.defaultAccountID = try? container.decodeIfPresent(String.self, forKey: .defaultAccountID)
    }
}
