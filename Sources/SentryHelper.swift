import CmuxSentryReporting
import Foundation
import Sentry

@MainActor private var sentryMemoryContextRefreshTask: Task<Void, Never>?
@MainActor private var sentryLastMemoryContextRefresh: Date?

/// Add a Sentry breadcrumb for user-action context in hang/crash reports.
func sentryBreadcrumb(_ message: String, category: String = "ui", data: [String: Any]? = nil) {
    // Sentry disabled: no-op
}

private func sentryCaptureMessage(
    _ message: String,
    level: SentryLevel,
    category: String,
    data: [String: Any]?,
    contextKey: String?
) {
    // Sentry disabled: no-op
}

func sentryCaptureWarning(
    _ message: String,
    category: String = "ui",
    data: [String: Any]? = nil,
    contextKey: String? = nil
) {
    // Sentry disabled: no-op
}

func sentryCaptureError(
    _ message: String,
    category: String = "ui",
    data: [String: Any]? = nil,
    contextKey: String? = nil
) {
    // Sentry disabled: no-op
}

@MainActor
func sentryStartMemoryContextRefresh() {
    // Sentry disabled: no-op
}

@MainActor
func sentryStopMemoryContextRefresh() {
    sentryMemoryContextRefreshTask?.cancel()
    sentryMemoryContextRefreshTask = nil
    sentryLastMemoryContextRefresh = nil
}

func sentryInstallDispatchMemoryWarnings() {
    // Sentry disabled: no-op
}

private func sentryRequestMemoryContextRefresh(reason: String) {
    // Sentry disabled: no-op
}

@MainActor
private func sentryScheduleMemoryContextRefresh(
    reason: String,
    minimumInterval: TimeInterval = 300
) {
    // Sentry disabled: no-op
}

/// Refresh the memory/surface context attached to future Sentry events.
#if compiler(>=6.2)
@concurrent
#else
@Sendable
#endif
nonisolated func sentryRefreshMemoryContext(reason: String) async {
    // Sentry disabled: no-op
}
