import Foundation

/// Represents a consolidated snapshot of an account's model quotas and buckets.
public struct GeminiQuotaSnapshot: Sendable, Codable, Equatable {
    /// Individual AI model quotas.
    public var models: [GeminiModelQuota]
    /// High-level quota groups returned by the summary endpoint.
    public var groups: [GeminiQuotaGroup]
    /// The user's subscription tier.
    public var tier: GeminiSubscriptionTier
    /// Whether access is forbidden (HTTP 403).
    public var isForbidden: Bool
    /// Explanation if access is forbidden.
    public var forbiddenReason: String?
    /// Epoch timestamp (seconds) when this snapshot was captured.
    public var lastUpdatedTimestamp: TimeInterval

    /// Creates an empty quota snapshot.
    public init(
        models: [GeminiModelQuota] = [],
        groups: [GeminiQuotaGroup] = [],
        tier: GeminiSubscriptionTier = .free,
        isForbidden: Bool = false,
        forbiddenReason: String? = nil,
        lastUpdatedTimestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.models = models
        self.groups = groups
        self.tier = tier
        self.isForbidden = isForbidden
        self.forbiddenReason = forbiddenReason
        self.lastUpdatedTimestamp = lastUpdatedTimestamp
    }

    /// Finds the flagship model representing this account (e.g. Gemini 3.8 Flash).
    public var flagshipModel: GeminiModelQuota? {
        guard !isForbidden else { return nil }
        let displayList = displayModels
        guard !displayList.isEmpty else { return nil }

        let geminiModels = displayList.filter { $0.id.hasPrefix("gemini") }
        let textGemini = geminiModels.filter { !$0.id.contains("image") }
        let pool = !textGemini.isEmpty ? textGemini : (!geminiModels.isEmpty ? geminiModels : displayList)

        // Select the newest generation, preferring flash over pro.
        return pool.sorted { a, b in
            let genA = Self.parseGeneration(from: a.id)
            let genB = Self.parseGeneration(from: b.id)
            let cmp = Self.compareGenerations(genA, genB)
            if cmp != 0 {
                return cmp > 0
            }
            let aIsFlash = a.id.contains("flash")
            let bIsFlash = b.id.contains("flash")
            if aIsFlash != bIsFlash {
                return aIsFlash
            }
            return a.percentage < b.percentage
        }.first
    }

    /// Deduplicated, highest-generation model entries for concise display.
    public var displayModels: [GeminiModelQuota] {
        var grouped: [String: [GeminiModelQuota]] = [:]
        for model in models {
            let base = Self.stripThinkingLevel(from: model.id)
            grouped[base, default: []].append(model)
        }

        var results: [GeminiModelQuota] = []
        for (base, variants) in grouped {
            guard let representative = variants.min(by: { $0.percentage < $1.percentage }) else { continue }
            results.append(GeminiModelQuota(
                id: base,
                displayName: Self.prettyModelName(for: base),
                percentage: representative.percentage,
                resetTime: representative.resetTime
            ))
        }

        return results.sorted { a, b in
            let orderA = Self.displayPriority(for: a.id)
            let orderB = Self.displayPriority(for: b.id)
            if orderA != orderB {
                return orderA < orderB
            }
            return a.id < b.id
        }
    }

    /// Locates the 5-hour quota bucket for a given model.
    ///
    /// - Parameter model: The target model.
    /// - Returns: The matching 5-hour ``GeminiQuotaBucket``, if available.
    public func bucket5h(for model: GeminiModelQuota) -> GeminiQuotaBucket? {
        guard let group = group(for: model) else { return nil }
        return group.buckets.first { b in
            let win = b.window.lowercased()
            let bid = b.id.lowercased()
            return win.contains("5h") || bid.contains("5h") || win.contains("hour") || bid.contains("hour")
        }
    }

    /// Locates the weekly quota bucket for a given model.
    ///
    /// - Parameter model: The target model.
    /// - Returns: The matching weekly ``GeminiQuotaBucket``, if available.
    public func bucketWeekly(for model: GeminiModelQuota) -> GeminiQuotaBucket? {
        guard let group = group(for: model) else { return nil }
        return group.buckets.first { b in
            let win = b.window.lowercased()
            let bid = b.id.lowercased()
            return win.contains("week") || bid.contains("week") || win.contains("7d") || bid.contains("7d")
        }
    }

    /// Finds the corresponding ``GeminiQuotaGroup`` for a model.
    public func group(for model: GeminiModelQuota) -> GeminiQuotaGroup? {
        let name = model.id.lowercased()
        let is3P = name.hasPrefix("claude") || name.hasPrefix("gpt")
        let isGemini = name.hasPrefix("gemini") || name.hasPrefix("imagen")

        for group in groups {
            let gn = group.displayName.lowercased()
            if is3P && (gn.contains("claude") || gn.contains("gpt") || gn.contains("3p")) {
                return group
            }
            if isGemini && (gn.contains("gemini") || (!gn.contains("claude") && !gn.contains("gpt") && !gn.contains("3p"))) {
                return group
            }
        }
        return nil
    }

    /// Formats an RFC3339 reset time into a human-friendly countdown string.
    ///
    /// - Parameters:
    ///   - rfc3339: The ISO8601/RFC3339 timestamp.
    ///   - wording: Action suffix (e.g. "后刷新", "后重置").
    ///   - now: Reference time for calculation (defaults to current date).
    /// - Returns: Localized countdown string.
    public static func countdownText(
        fromRFC3339 rfc3339: String?,
        wording: String = "后刷新",
        now: Date = Date()
    ) -> String {
        guard let rfc3339, !rfc3339.isEmpty else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var targetDate = formatter.date(from: rfc3339)
        if targetDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            targetDate = formatter.date(from: rfc3339)
        }
        guard let date = targetDate else { return "" }

        let delta = date.timeIntervalSince(now)
        if delta <= 0 {
            return "即将\(wording)"
        }

        let totalMinutes = Int((delta / 60.0).rounded())
        if totalMinutes < 1 {
            return "即将\(wording)"
        }
        if totalMinutes < 60 {
            return "\(totalMinutes)m\(wording)"
        }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours < 24 {
            if mins == 0 {
                return "\(hours)h\(wording)"
            }
            return "\(hours)h\(mins)m\(wording)"
        }
        let days = hours / 24
        let remHours = hours % 24
        if remHours == 0 {
            return "\(days)天\(wording)"
        }
        return "\(days)天\(remHours)h\(wording)"
    }

    /// Strips thinking suffixes (-high, -medium, -low, -minimal, etc.).
    public static func stripThinkingLevel(from name: String) -> String {
        let suffixes = ["-extra-low", "-thinking", "-minimal", "-tiered", "-agent",
                        "-high", "-medium", "-low", "-none", "-lite"]
        for suffix in suffixes {
            if name.hasSuffix(suffix) && name.count > suffix.count {
                return String(name.dropLast(suffix.count))
            }
        }
        return name
    }

    /// Converts raw identifier to pretty display title.
    public static func prettyModelName(for base: String) -> String {
        let parts = base.split(separator: "-").map(String.init)
        guard !parts.isEmpty else { return base }

        var capitalized: [String] = []
        for (idx, part) in parts.enumerated() {
            let low = part.lowercased()
            if low == "gpt" { capitalized.append("GPT") }
            else if low == "oss" { capitalized.append("OSS") }
            else if low == "ai" { capitalized.append("AI") }
            else if idx == 0 { capitalized.append(part.capitalized) }
            else if let _ = Double(part) { capitalized.append(part) }
            else { capitalized.append(part.capitalized) }
        }
        return capitalized.joined(separator: " ")
    }

    private static func parseGeneration(from modelID: String) -> [Int] {
        let base = stripThinkingLevel(from: modelID)
        let parts = base.split(separator: "-")
        for part in parts {
            if let ver = Double(part) {
                let sub = String(part).split(separator: ".").compactMap { Int($0) }
                if !sub.isEmpty { return sub }
            }
        }
        return []
    }

    private static func compareGenerations(_ a: [Int], _ b: [Int]) -> Int {
        let maxCount = max(a.count, b.count)
        for i in 0..<maxCount {
            let valA = i < a.count ? a[i] : 0
            let valB = i < b.count ? b[i] : 0
            if valA != valB {
                return valA > valB ? 1 : -1
            }
        }
        return 0
    }

    private static func displayPriority(for modelID: String) -> Int {
        if modelID.hasPrefix("gemini") {
            if modelID.contains("flash") { return 10 }
            if modelID.contains("pro") { return 20 }
            return 30
        }
        if modelID.hasPrefix("claude") { return 40 }
        if modelID.hasPrefix("gpt") { return 50 }
        return 99
    }
}
