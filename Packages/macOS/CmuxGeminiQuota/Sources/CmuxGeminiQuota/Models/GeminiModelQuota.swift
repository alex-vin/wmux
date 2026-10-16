public import Foundation

/// Represents the quota status of an individual AI model.
public struct GeminiModelQuota: Sendable, Codable, Identifiable, Equatable {
    /// The unique model identifier, e.g. "gemini-3.8-flash-high".
    public let id: String
    /// The formatted display name, e.g. "Gemini 3.8 Flash".
    public let displayName: String
    /// The remaining quota percentage from 0 to 100.
    public var percentage: Int
    /// The RFC3339 reset time string, if available.
    public var resetTime: String?

    /// Creates a model quota entry.
    ///
    /// - Parameters:
    ///   - id: The model identifier.
    ///   - displayName: Human-readable model name.
    ///   - percentage: Remaining quota percentage (0 - 100).
    ///   - resetTime: Optional RFC3339 reset timestamp.
    public init(id: String, displayName: String, percentage: Int, resetTime: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.percentage = max(0, min(100, percentage))
        self.resetTime = resetTime
    }
}
