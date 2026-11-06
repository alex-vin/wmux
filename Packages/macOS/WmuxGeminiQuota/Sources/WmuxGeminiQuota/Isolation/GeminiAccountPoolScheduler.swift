public import Foundation
public import Observation

/// Manages account scheduling, quota-weighted scoring, and active session distribution for multi-account Gemini pools.
@MainActor
@Observable
public final class GeminiAccountPoolScheduler {
    /// Account store providing pool candidates.
    public let accountStore: GeminiAccountStore

    /// Storage location for cooling accounts JSON.
    public let storageURL: URL

    /// Cooldown expiration timestamps by account ID (e.g. after encountering 429 RESOURCE_EXHAUSTED).
    public var coolingAccounts: [String: Date] = [:]

    /// Active terminal surface count per account ID.
    public var activeSessionCounts: [String: Int] = [:]

    /// Primary configuration file for wmux cooling accounts.
    public static var defaultStorageURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/wmux/cooling_accounts.json")
    }

    /// Fallback configuration file for cmux cooling accounts.
    public static var fallbackStorageURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/cmux/cooling_accounts.json")
    }

    /// Initializes an account pool scheduler.
    ///
    /// - Parameters:
    ///   - accountStore: The active Gemini account store.
    ///   - storageURL: Optional custom storage path for cooling accounts (defaults to ~/.config/wmux/cooling_accounts.json).
    public init(
        accountStore: GeminiAccountStore,
        storageURL: URL = GeminiAccountPoolScheduler.defaultStorageURL
    ) {
        self.accountStore = accountStore
        self.storageURL = storageURL
        loadFromDisk()
    }

    /// Evaluates candidate accounts and selects the optimal account based on health scoring.
    ///
    /// Filters out:
    /// - Accounts matching `excludingAccountID` (to avoid subagent colliding with parent agent)
    /// - Disabled or forbidden accounts
    /// - Accounts in `coolingAccounts` whose cooldown hasn't expired
    /// - Accounts with weekly quota depleted (`weeklyQuota <= 0.05`)
    ///
    /// - Parameter excludingAccountID: Optional account ID to exclude.
    /// - Returns: The account with the highest score, or `nil` if no viable accounts exist.
    public func pickOptimalAccount(excludingAccountID: String? = nil) -> GeminiAccount? {
        let now = Date()

        // Auto circuit breaker: if any account in store is rate-limited, ensure it is cooled down
        for account in accountStore.accounts {
            if (account.quota.isRateLimited || (account.quota.isForbidden && account.quota.forbiddenReason?.contains("429") == true)) && !isCooling(accountID: account.id, now: now) {
                markCooling(accountID: account.id, duration: 900)
            }
        }

        var availableAccounts = accountStore.accounts.filter { account in
            if account.isDisabled || account.quota.isForbidden || account.quota.isRateLimited {
                return false
            }
            if let excludingAccountID, account.id == excludingAccountID {
                return false
            }
            if let coolUntil = coolingAccounts[account.id], coolUntil > now {
                return false
            }
            if let weekly = account.weeklyQuota, weekly <= 0.05 {
                return false
            }
            return true
        }

        // If excluding parent account leaves no options, gracefully fall back to all healthy accounts
        if availableAccounts.isEmpty, excludingAccountID != nil {
            availableAccounts = accountStore.accounts.filter { account in
                if account.isDisabled || account.quota.isForbidden || account.quota.isRateLimited {
                    return false
                }
                if let coolUntil = coolingAccounts[account.id], coolUntil > now {
                    return false
                }
                if let weekly = account.weeklyQuota, weekly <= 0.05 {
                    return false
                }
                return true
            }
        }

        return availableAccounts.max { a, b in
            score(for: a) < score(for: b)
        }
    }

    /// Computes the quota health score for a given account.
    ///
    /// Formula: `Score = (Quota_5h * 0.6) + (Quota_weekly * 0.3) - (activeCount * 20.0)`
    ///
    /// - Parameter account: The account to evaluate.
    /// - Returns: The calculated score value.
    public func score(for account: GeminiAccount) -> Double {
        let quota5h = (account.fiveHourQuota ?? 0.0) * 100.0
        let quotaWeekly = (account.weeklyQuota ?? 0.0) * 100.0
        let active = Double(activeSessionCounts[account.id] ?? 0)

        return (quota5h * 0.6) + (quotaWeekly * 0.3) - (active * 20.0)
    }

    /// Increments the active terminal count for an account.
    ///
    /// - Parameter accountID: Identifier of the account.
    public func incrementActive(for accountID: String) {
        activeSessionCounts[accountID, default: 0] += 1
    }

    /// Decrements the active terminal count for an account.
    ///
    /// - Parameter accountID: Identifier of the account.
    public func decrementActive(for accountID: String) {
        let current = activeSessionCounts[accountID] ?? 0
        if current <= 1 {
            activeSessionCounts.removeValue(forKey: accountID)
        } else {
            activeSessionCounts[accountID] = current - 1
        }
    }

    /// Marks an account into cooling status for a specified duration and persists to disk.
    ///
    /// - Parameters:
    ///   - accountID: Identifier of the account.
    ///   - duration: Cooldown duration in seconds (default is 900s / 15 minutes).
    public func markCooling(accountID: String, duration: TimeInterval = 900) {
        coolingAccounts[accountID] = Date().addingTimeInterval(duration)
        saveToDisk()
    }

    /// Checks whether an account is currently cooling down.
    ///
    /// - Parameters:
    ///   - accountID: Identifier of the account.
    ///   - now: Reference date (defaults to current date).
    /// - Returns: `true` if cooling down, `false` otherwise.
    public func isCooling(accountID: String, now: Date = Date()) -> Bool {
        if let coolUntil = coolingAccounts[accountID] {
            return coolUntil > now
        }
        return false
    }

    /// Clears cooling status for a specific account or all accounts and persists to disk.
    ///
    /// - Parameter accountID: Optional account ID to clear. If `nil`, all cooldowns are cleared.
    public func clearCooling(for accountID: String? = nil) {
        if let accountID {
            coolingAccounts.removeValue(forKey: accountID)
        } else {
            coolingAccounts.removeAll()
        }
        saveToDisk()
    }

    private func loadFromDisk() {
        let fm = FileManager.default
        let urlToLoad: URL?
        if fm.fileExists(atPath: storageURL.path) {
            urlToLoad = storageURL
        } else if storageURL == Self.defaultStorageURL && fm.fileExists(atPath: Self.fallbackStorageURL.path) {
            urlToLoad = Self.fallbackStorageURL
        } else {
            urlToLoad = nil
        }

        guard let urlToLoad, let data = try? Data(contentsOf: urlToLoad) else { return }
        try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: urlToLoad.path)

        guard let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }

        let formatterWithFrac = ISO8601DateFormatter()
        formatterWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatterStd = ISO8601DateFormatter()
        formatterStd.formatOptions = [.withInternetDateTime]

        let now = Date()
        var valid: [String: Date] = [:]
        for (accountID, value) in raw {
            var expiry: Date? = nil
            if let str = value as? String {
                expiry = formatterWithFrac.date(from: str) ?? formatterStd.date(from: str)
            } else if let num = value as? NSNumber {
                expiry = Date(timeIntervalSince1970: num.doubleValue)
            }
            if let expiry, expiry > now {
                valid[accountID] = expiry
            }
        }

        self.coolingAccounts = valid

        // Prune expired entries from disk if any expired accounts were removed
        if valid.count < raw.count {
            saveToDisk()
        }
    }

    private func saveToDisk() {
        let parentDir = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        var payload: [String: String] = [:]
        for (accID, date) in coolingAccounts {
            payload[accID] = formatter.string(from: date)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else { return }

        do {
            try data.write(to: storageURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
        } catch {
            // Fallback to cmux if primary write failed and using default path
            if storageURL == Self.defaultStorageURL {
                let fallback = Self.fallbackStorageURL
                let fallbackDir = fallback.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: fallbackDir, withIntermediateDirectories: true)
                try? data.write(to: fallback, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fallback.path)
            }
        }
    }
}
