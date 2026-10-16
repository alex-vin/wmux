import Foundation
import Testing
@testable import CmuxGeminiQuota

@Suite("GeminiQuotaParsingTests")
struct GeminiQuotaParsingTests {
    @Test("Countdown string formatting")
    func countdownFormatting() {
        let now = Date(timeIntervalSince1970: 1700000000)

        // 45 minutes later
        let date45m = Date(timeIntervalSince1970: 1700000000 + 45 * 60)
        let rfc45m = ISO8601DateFormatter().string(from: date45m)
        #expect(GeminiQuotaSnapshot.countdownText(fromRFC3339: rfc45m, wording: "后刷新", now: now) == "45m后刷新")

        // 3 hours 26 minutes later
        let date3h26m = Date(timeIntervalSince1970: 1700000000 + (3 * 3600 + 26 * 60))
        let rfc3h26m = ISO8601DateFormatter().string(from: date3h26m)
        #expect(GeminiQuotaSnapshot.countdownText(fromRFC3339: rfc3h26m, wording: "后刷新", now: now) == "3h26m后刷新")

        // 5 days 18 hours later
        let date5d18h = Date(timeIntervalSince1970: 1700000000 + (5 * 86400 + 18 * 3600))
        let rfc5d18h = ISO8601DateFormatter().string(from: date5d18h)
        #expect(GeminiQuotaSnapshot.countdownText(fromRFC3339: rfc5d18h, wording: "后重置", now: now) == "5天18h后重置")
    }

    @Test("Model thinking level stripping")
    func thinkingLevelStripping() {
        #expect(GeminiQuotaSnapshot.stripThinkingLevel(from: "gemini-3.8-flash-high") == "gemini-3.8-flash")
        #expect(GeminiQuotaSnapshot.stripThinkingLevel(from: "gemini-3-pro-medium") == "gemini-3-pro")
        #expect(GeminiQuotaSnapshot.stripThinkingLevel(from: "claude-sonnet-4-6-thinking") == "claude-sonnet-4-6")
    }

    @Test("Flagship model detection")
    func flagshipModelDetection() {
        let models = [
            GeminiModelQuota(id: "gemini-2.5-pro-high", displayName: "Gemini 2.5 Pro", percentage: 50),
            GeminiModelQuota(id: "gemini-3.8-flash-high", displayName: "Gemini 3.8 Flash", percentage: 85),
            GeminiModelQuota(id: "gemini-3.8-flash-image", displayName: "Gemini 3.8 Flash Image", percentage: 90),
            GeminiModelQuota(id: "claude-sonnet-4-6", displayName: "Claude Sonnet 4.6", percentage: 100),
        ]
        let snapshot = GeminiQuotaSnapshot(models: models)
        let flagship = snapshot.flagshipModel
        #expect(flagship?.id == "gemini-3.8-flash")
        #expect(flagship?.percentage == 85)
    }
}
