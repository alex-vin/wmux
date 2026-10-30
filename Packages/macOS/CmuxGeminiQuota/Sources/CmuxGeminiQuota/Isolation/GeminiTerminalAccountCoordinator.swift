public import Foundation
public import Observation

/// Coordinates per-terminal surface Gemini account assignments and token provisioning.
@MainActor
@Observable
public final class GeminiTerminalAccountCoordinator {
    /// Maps each Terminal Surface UUID to its designated Gemini account ID.
    public private(set) var surfaceBindings: [UUID: String] = [:]

    /// Load-balancing and session-aware scheduler for multi-account pools.
    public let scheduler: GeminiAccountPoolScheduler

    /// Base directory for per-account shadow home and keychain storage.
    public let accountsBaseDirectory: URL

    /// Base directory for per-surface token bridge files.
    public let tokenCacheDirectory: URL

    private let accountStore: GeminiAccountStore

    /// Default base directory for per-surface token bridge files.
    public static var defaultTokenCacheDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/cmux/gemini_tokens")
    }

    /// Default base directory for per-account shadow home and keychain storage.
    public static var defaultAccountsBaseDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/cmux/accounts")
    }

    /// Backwards compatibility aliases
    public static var tokenCacheDirectory: URL { defaultTokenCacheDirectory }
    public static var accountsBaseDirectory: URL { defaultAccountsBaseDirectory }

    /// Creates a terminal coordinator.
    ///
    /// - Parameters:
    ///   - accountStore: The active Gemini account store.
    ///   - scheduler: Optional custom account pool scheduler.
    ///   - accountsBaseDirectory: Base directory for accounts (defaults to `~/.config/cmux/accounts`).
    ///   - tokenCacheDirectory: Base directory for tokens (defaults to `~/.config/cmux/gemini_tokens`).
    public init(
        accountStore: GeminiAccountStore,
        scheduler: GeminiAccountPoolScheduler? = nil,
        accountsBaseDirectory: URL = GeminiTerminalAccountCoordinator.defaultAccountsBaseDirectory,
        tokenCacheDirectory: URL = GeminiTerminalAccountCoordinator.defaultTokenCacheDirectory
    ) {
        self.accountStore = accountStore
        self.scheduler = scheduler ?? GeminiAccountPoolScheduler(accountStore: accountStore)
        self.accountsBaseDirectory = accountsBaseDirectory
        self.tokenCacheDirectory = tokenCacheDirectory
        Self.cleanupHostUserKeychainListIfNeeded()
    }

    /// Automatically selects the optimal account from the pool and binds it to a terminal surface.
    ///
    /// - Parameters:
    ///   - surfaceID: Unique UUID of the terminal pane.
    ///   - excludingAccountID: Optional account ID to exclude (e.g. parent agent's account).
    /// - Returns: The bound account if one was available, or `nil`.
    @discardableResult
    public func bindAuto(surfaceID: UUID, excludingAccountID: String? = nil) -> GeminiAccount? {
        guard let optimal = scheduler.pickOptimalAccount(excludingAccountID: excludingAccountID) else {
            return nil
        }
        if let previousID = surfaceBindings[surfaceID] {
            scheduler.decrementActive(for: previousID)
        }
        surfaceBindings[surfaceID] = optimal.id
        scheduler.incrementActive(for: optimal.id)
        syncTokenCache(for: surfaceID)
        return optimal
    }

    /// Releases a terminal surface assignment and decrements its active session count.
    ///
    /// - Parameter surfaceID: Unique UUID of the terminal pane.
    public func release(surfaceID: UUID) {
        if let boundAccountID = surfaceBindings[surfaceID] {
            scheduler.decrementActive(for: boundAccountID)
        }
        unbind(surfaceID: surfaceID)
    }

    /// Assigns a Gemini account to a specific terminal surface.
    ///
    /// - Parameters:
    ///   - surfaceID: Unique UUID of the terminal pane.
    ///   - accountID: ID (email) of the Gemini account.
    public func bind(surfaceID: UUID, to accountID: String) {
        surfaceBindings[surfaceID] = accountID
        syncTokenCache(for: surfaceID)
    }

    /// Removes any custom account assignment for a surface, falling back to the default account.
    ///
    /// - Parameter surfaceID: Unique UUID of the terminal pane.
    public func unbind(surfaceID: UUID) {
        surfaceBindings.removeValue(forKey: surfaceID)
        clearTokenCache(for: surfaceID)
    }

    /// Resolves the effective account for a given terminal surface.
    ///
    /// - Parameters:
    ///   - surfaceID: Terminal surface UUID.
    ///   - fallback: Whether to return the global default account if unassigned.
    /// - Returns: The resolved ``GeminiAccount``.
    public func effectiveAccount(for surfaceID: UUID, fallback: Bool = true) -> GeminiAccount? {
        if let boundID = surfaceBindings[surfaceID], let bound = accountStore.account(for: boundID) {
            return bound
        }
        return fallback ? accountStore.defaultAccount : nil
    }

    /// Generates the raw `go-keyring-base64:...` token string for `agy` execution in this terminal.
    ///
    /// - Parameter surfaceID: Terminal surface UUID.
    /// - Returns: Formatted base64 keyring secret string.
    public func keyringToken(for surfaceID: UUID) -> String? {
        effectiveAccount(for: surfaceID)?.agyKeyringSecretValue()
    }

    private func syncTokenCache(for surfaceID: UUID) {
        guard let account = effectiveAccount(for: surfaceID) else { return }
        let fm = FileManager.default
        let userHome = fm.homeDirectoryForCurrentUser

        // 1. Prepare shadow home directory
        let safeAccountID = account.id.replacingOccurrences(of: "@", with: "_at_").replacingOccurrences(of: ".", with: "_")
        let accountHome = accountsBaseDirectory.appendingPathComponent(safeAccountID)
        let keychainsDir = accountHome.appendingPathComponent("Library/Keychains")
        let preferencesDir = accountHome.appendingPathComponent("Library/Preferences")
        let keychainDB = keychainsDir.appendingPathComponent("account.keychain-db")

        try? fm.createDirectory(at: keychainsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: preferencesDir, withIntermediateDirectories: true)

        // Remove any legacy corrupted login.keychain-db in this account folder
        let legacyKeychainDB = keychainsDir.appendingPathComponent("login.keychain-db")
        if fm.fileExists(atPath: legacyKeychainDB.path) {
            try? fm.removeItem(at: legacyKeychainDB)
        }

        // 2. Symlink developer tools to preserve git identity and ssh access
        symlinkIfMissing(source: userHome.appendingPathComponent(".gitconfig"), target: accountHome.appendingPathComponent(".gitconfig"))
        symlinkIfMissing(source: userHome.appendingPathComponent(".ssh"), target: accountHome.appendingPathComponent(".ssh"))
        symlinkIfMissing(source: userHome.appendingPathComponent(".gemini"), target: accountHome.appendingPathComponent(".gemini"))

        // 3. Populate dedicated keychain
        let token = account.agyKeyringSecretValue()
        provisionKeychain(at: keychainDB, homeDirectory: accountHome, secret: token)

        // 4. Write surface environment script
        let tokensDir = tokenCacheDirectory
        try? fm.createDirectory(at: tokensDir, withIntermediateDirectories: true)
        let envScriptPath = tokensDir.appendingPathComponent("\(surfaceID.uuidString).env")
        let envScriptContent = """
        # Auto-generated by wmux for surface \(surfaceID.uuidString)
        export REAL_USER_HOME="\(userHome.path)"
        export HOME="\(accountHome.path)"
        export CMUX_AGY_ISOLATED_ACCOUNT="\(account.id)"
        /usr/bin/security unlock-keychain -p "" "\(keychainDB.path)" >/dev/null 2>&1 || true
        """
        try? envScriptContent.write(to: envScriptPath, atomically: true, encoding: .utf8)
    }

    private func clearTokenCache(for surfaceID: UUID) {
        let envScript = tokenCacheDirectory.appendingPathComponent("\(surfaceID.uuidString).env")
        try? FileManager.default.removeItem(at: envScript)
    }

    private func symlinkIfMissing(source: URL, target: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.path) && !fm.fileExists(atPath: target.path) else { return }
        try? fm.createSymbolicLink(at: target, withDestinationURL: source)
    }

    private func provisionKeychain(at keychainURL: URL, homeDirectory: URL, secret: String) {
        let path = keychainURL.path
        let fm = FileManager.default
        let env = [
            "HOME": homeDirectory.path,
            "PATH": "/usr/bin:/bin"
        ]

        @discardableResult
        func runSecurity(arguments: [String]) -> Int32 {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
            p.arguments = arguments
            p.environment = env
            let pipe = Pipe()
            p.standardOutput = pipe
            p.standardError = pipe
            try? p.run()
            p.waitUntilExit()
            return p.terminationStatus
        }

        var needsCreate = !fm.fileExists(atPath: path)
        if !needsCreate {
            let unlockStatus = runSecurity(arguments: ["unlock-keychain", "-p", "", path])
            if unlockStatus != 0 {
                try? fm.removeItem(at: keychainURL)
                needsCreate = true
            }
        }

        if needsCreate {
            _ = runSecurity(arguments: ["create-keychain", "-p", "", path])
        }

        _ = runSecurity(arguments: ["set-keychain-settings", "-u", path])
        _ = runSecurity(arguments: ["unlock-keychain", "-p", "", path])
        // Delete existing item if present to prevent macOS SecurityAgent popup on update (-U)
        _ = runSecurity(arguments: ["delete-generic-password", "-s", "gemini", "-a", "antigravity", path])
        _ = runSecurity(arguments: ["add-generic-password", "-s", "gemini", "-a", "antigravity", "-w", secret, "-A", path])
        _ = runSecurity(arguments: ["default-keychain", "-d", "user", "-s", path])
        _ = runSecurity(arguments: ["list-keychains", "-d", "user", "-s", path])
    }

    private static func cleanupHostUserKeychainListIfNeeded() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["list-keychains", "-d", "user"]
        let pipe = Pipe()
        p.standardOutput = pipe
        try? p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }

        let currentPaths = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            .filter { !$0.isEmpty }

        let filtered = currentPaths.filter { !$0.contains(".config/cmux/accounts") }
        if filtered.count != currentPaths.count && !filtered.isEmpty {
            let setProcess = Process()
            setProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
            setProcess.arguments = ["list-keychains", "-d", "user", "-s"] + filtered
            try? setProcess.run()
            setProcess.waitUntilExit()
        }
    }
}
