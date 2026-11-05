public import Foundation

/// Shared interpretation of HTTP `Retry-After` for every automatic client
/// retry owner. A server directive is a minimum wait, never a replacement for
/// a longer local backoff.
public struct WmuxRetryAfterPolicy: Sendable {
    public init() {}

    public let defaultRateLimitSeconds = 60

    /// Parses either delta-seconds or an HTTP-date. Invalid, zero, and expired
    /// directives return nil so callers can apply their documented fallback.
    public func seconds(
        from value: String?,
        now: Date = Date()
    ) -> Int? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        if let seconds = Int(raw), seconds > 0 {
            return seconds
        }
        for format in [
            "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'",
            "EEEE',' dd-MMM-yy HH':'mm':'ss 'GMT'",
            "EEE MMM d HH':'mm':'ss yyyy",
        ] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let deadline = formatter.date(from: raw) {
                let remaining = roundedUpSeconds(deadline.timeIntervalSince(now))
                return remaining > 0 ? remaining : nil
            }
        }
        return nil
    }

    public func seconds(
        from response: HTTPURLResponse,
        now: Date = Date(),
        defaultSeconds: Int? = nil
    ) -> Int? {
        seconds(
            from: response.value(forHTTPHeaderField: "Retry-After"),
            now: now
        ) ?? defaultSeconds.flatMap { $0 > 0 ? $0 : nil }
    }

    public func delay(
        localSeconds: TimeInterval,
        retryAfterSeconds: Int?
    ) -> TimeInterval {
        max(localSeconds, TimeInterval(max(0, retryAfterSeconds ?? 0)))
    }

    /// Floating point rounds Int.max up to 2^63. Saturate that conversion
    /// without shortening ordinary server directives or trapping on restore.
    public func roundedUpSeconds(_ seconds: TimeInterval) -> Int {
        guard seconds > 0 else { return 0 }
        let rounded = seconds.rounded(.up)
        return rounded >= Double(Int.max) ? Int.max : Int(rounded)
    }

    /// Sleep in representable chunks while preserving the entire requested
    /// wait. Converting an arbitrary server delay to UInt64 nanoseconds traps.
    public func sleep(
        seconds: TimeInterval,
        using sleeper: @Sendable (TimeInterval) async throws -> Void = {
            try await Task<Never, Never>.sleep(for: .seconds($0))
        }
    ) async throws {
        var remaining = seconds
        while remaining > 0 {
            try Task.checkCancellation()
            let chunk = min(remaining, 86_400)
            try await sleeper(chunk)
            remaining -= chunk
        }
    }
}

public typealias CmxRetryAfterPolicy = WmuxRetryAfterPolicy

public protocol CmxRetryAfterProviding {
    var retryAfterSeconds: Int? { get }
}

public actor CmxRetryAfterGate {
    private var until: Date?
    public init() {}
    public func wait() async throws {
        guard let until = until else { return }
        let remaining = until.timeIntervalSinceNow
        if remaining > 0 {
            try await Task.sleep(for: .seconds(remaining))
        }
    }
    public func extend(by seconds: Int) {
        let deadline = Date().addingTimeInterval(TimeInterval(seconds))
        if let current = until {
            until = max(current, deadline)
        } else {
            until = deadline
        }
    }
}

