import AppKit
import Foundation

/// PostHogAnalytics stubbed for pure local macOS operation without external telemetry.
final class PostHogAnalytics: @unchecked Sendable {
    static let shared = PostHogAnalytics()

    var isCaptureEnabled: Bool { false }

    init() {}

    func recordLaunchIdentity() {}
    func startIfNeeded() {}
    func trackActive(reason: String) {}
    func register(_ properties: [String: Any]) {}
    func capture(_ event: String, properties: [String: Any]) {}
    func identify(accountID: String) {}
    func resetIdentity() {}
    func captureCrashException(pendingCrash: GhosttyCrashBreadcrumb.PendingCrash) {}
    func trackDailyActive(reason: String) {}
    func trackHourlyActive(reason: String) {}
    func flush() {}
}
