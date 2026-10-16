import Foundation

/// Represents the subscription tier of a Google Gemini user account.
public enum GeminiSubscriptionTier: String, Sendable, Codable, CaseIterable {
    /// Free tier without a paid subscription.
    case free = "FREE"
    /// Standard paid Google One AI Premium / Pro subscription.
    case pro = "PRO"
    /// High-tier Google Gemini Ultra / Helium tier.
    case ultra = "ULTRA"

    /// Normalizes raw tier strings returned from the Code Assist API.
    ///
    /// - Parameter raw: The raw tier string, such as "starter", "premium", "ultra".
    /// - Returns: The canonical ``GeminiSubscriptionTier``.
    public static func normalize(_ raw: String?) -> GeminiSubscriptionTier {
        guard let raw = raw?.lowercased() else { return .free }
        if raw.contains("ultra") || raw.contains("helium") {
            return .ultra
        }
        if raw.contains("pro") || raw.contains("premium") || raw.contains("advanced") {
            return .pro
        }
        return .free
    }
}
