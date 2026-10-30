public import Foundation
public import Observation

/// Manages account scheduling, quota-weighted scoring, and active session distribution for multi-account Gemini pools.
@MainActor
@Observable
public final class GeminiAccountPoolScheduler {
    /// Account store providing pool candidates.
    public let accountStore: GeminiAccountStore

    /// Cooldown expiration timestamps by account ID (e.g. after encountering 429 RESOURCE_EXHAUSTED).
    public var coolingAccounts: [String: Date] = [:]

    /// Active terminal surface count per account ID.
    public var activeSessionCounts: [String: Int] = [:]

    /// Initializes an account pool scheduler.
    ///
    /// - Parameter accountStore: The active Gemini account store.
    public init(accountStore: GeminiAccountStore) {
        self.accountStore = accountStore
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
        let availableAccounts = accountStore.accounts.filter { account in
            if account.isDisabled || account.quota.isForbidden {
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

    /// Marks an account into cooling status for a specified duration.
    ///
    /// - Parameters:
    ///   - accountID: Identifier of the account.
    ///   - duration: Cooldown duration in seconds (default is 900s / 15 minutes).
    public func markCooling(accountID: String, duration: TimeInterval = 900) {
        coolingAccounts[accountID] = Date().addingTimeInterval(duration)
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

    /// Clears cooling status for a specific account or all accounts.
    ///
    /// - Parameter accountID: Optional account ID to clear. If `nil`, all cooldowns are cleared.
    public func clearCooling(for accountID: String? = nil) {
        if let accountID {
            coolingAccounts.removeValue(forKey: accountID)
        } else {
            coolingAccounts.removeAll()
        }
    }
}
