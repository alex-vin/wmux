import Foundation

/// Represents a quota bucket from Google's `retrieveUserQuotaSummary` endpoint.
public struct GeminiQuotaBucket: Sendable, Codable, Identifiable, Equatable {
    /// Identifier of the bucket, e.g. "gemini-weekly", "gemini-5h".
    public let id: String
    /// The window kind, e.g. "weekly", "5h".
    public let window: String
    /// The remaining fraction from 0.0 to 1.0.
    public let remainingFraction: Double
    /// The RFC3339 reset time string.
    public let resetTime: String?
    /// Display name of the bucket.
    public let displayName: String?

    /// Remaining quota percentage (0 - 100).
    public var remainingPercentage: Int {
        Int((remainingFraction * 100.0).rounded())
    }

    /// Creates a quota bucket.
    ///
    /// - Parameters:
    ///   - id: The bucket ID.
    ///   - window: The window descriptor.
    ///   - remainingFraction: Remaining fraction (0.0 to 1.0).
    ///   - resetTime: Optional reset timestamp string.
    ///   - displayName: Optional display label.
    public init(
        id: String,
        window: String,
        remainingFraction: Double,
        resetTime: String? = nil,
        displayName: String? = nil
    ) {
        self.id = id
        self.window = window
        self.remainingFraction = max(0.0, min(1.0, remainingFraction))
        self.resetTime = resetTime
        self.displayName = displayName
    }

    public enum CodingKeys: String, CodingKey {
        case id, window, remainingFraction, resetTime, displayName
    }

    public init(from decoder: any Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container?.decodeIfPresent(String.self, forKey: .id)) ?? "unknown"
        self.window = (try? container?.decodeIfPresent(String.self, forKey: .window)) ?? ""
        if let fraction = try? container?.decodeIfPresent(Double.self, forKey: .remainingFraction) {
            self.remainingFraction = max(0.0, min(1.0, fraction))
        } else if let str = try? container?.decodeIfPresent(String.self, forKey: .remainingFraction),
                  let d = Double(str) {
            self.remainingFraction = max(0.0, min(1.0, d))
        } else {
            self.remainingFraction = 1.0
        }
        self.resetTime = try? container?.decodeIfPresent(String.self, forKey: .resetTime)
        self.displayName = try? container?.decodeIfPresent(String.self, forKey: .displayName)
    }
}
