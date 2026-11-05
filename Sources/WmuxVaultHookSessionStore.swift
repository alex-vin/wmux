import Foundation

/// A cmux-owned hook-session store that a built-in Vault agent may read.
enum WmuxVaultHookSessionStore: String, Codable, Hashable, Sendable {
    case amp
}
