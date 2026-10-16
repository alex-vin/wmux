import Foundation

/// Represents a group of quota buckets (e.g. Gemini Models, Third-Party Models).
public struct GeminiQuotaGroup: Sendable, Codable, Equatable {
    /// Display name of the group.
    public let displayName: String
    /// The buckets contained within this group.
    public let buckets: [GeminiQuotaBucket]

    /// Creates a quota group.
    ///
    /// - Parameters:
    ///   - displayName: Group display name.
    ///   - buckets: List of quota buckets.
    public init(displayName: String, buckets: [GeminiQuotaBucket]) {
        self.displayName = displayName
        self.buckets = buckets
    }
}
