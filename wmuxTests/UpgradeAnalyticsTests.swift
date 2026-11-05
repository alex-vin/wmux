import AppKit
import CMUXMobileCore
import CmuxCloud
import CmuxProductAnalytics
import Foundation
import os
import Testing

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// Records the events a ``ProductAnalytics`` sends, for app-level analytics tests.
private final class RecordingSink: AnalyticsEmitting {
    // Written by the pipeline actor, read by the test after `drain()`.
    private let state = OSAllocatedUnfairLock<[(String, [String: AnalyticsValue])]>(initialState: [])
    var events: [(name: String, properties: [String: AnalyticsValue])] { state.withLock { $0.map { (name: $0.0, properties: $0.1) } } }
    func named(_ name: String) -> [[String: AnalyticsValue]] { events.filter { $0.name == name }.map(\.properties) }

    func capture(_ event: String, _ properties: [String: AnalyticsValue]) { state.withLock { $0.append((event, properties)) } }
    func identify(userId: String?, alias: String?, properties: [String: AnalyticsValue]) {}
    func setSuperProperties(_ properties: [String: AnalyticsValue]) {}
    func flush() async {}
}

private enum TestAnalytics {
    static let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)

    /// An emitter with its own ledger suite. Remove the suite with
    /// ``remove(_:)`` once the test has drained the emitter.
    static func make(enabled: Bool = true) -> (ProductAnalytics, RecordingSink, String) {
        let sink = RecordingSink()
        let suiteName = "UpgradeAnalyticsTests.\(UUID().uuidString)"
        let analytics = ProductAnalytics(
            isEnabled: enabled,
            sink: sink,
            ledger: ProductAnalyticsLedger(defaults: UserDefaults(suiteName: suiteName)!),
            context: ProductAnalyticsContext(appVersion: "0.66.0", appBuild: "1", channel: "dev", osVersion: "15.5"),
            isPreexistingInstall: true
        )
        return (analytics, sink, suiteName)
    }

    static func remove(_ suiteName: String) {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }
}

@Suite("Account analytics transitions")
struct AccountAnalyticsStateTests {
    @Test("restore identifies without a sign-in success; a started sign-in succeeds once")
    func signInLifecycle() {
        var state = AccountAnalyticsState()
        let restoring = state.observe(userID: nil, isSettling: true, failure: nil)
        let restored = state.observe(userID: "u1", isSettling: false, failure: nil)
        let signedOut = state.observe(userID: nil, isSettling: false, failure: nil)
        state.signInStarted()
        let waiting = state.observe(userID: nil, isSettling: true, failure: nil)
        let signedIn = state.observe(userID: "u2", isSettling: false, failure: nil)
        let unchanged = state.observe(userID: "u2", isSettling: false, failure: nil)
        #expect(restoring.isEmpty)
        #expect(restored == [.identify(userID: "u1")])
        #expect(signedOut == [.signedOut])
        #expect(waiting.isEmpty)
        #expect(signedIn == [.identify(userID: "u2"), .signInSucceeded])
        #expect(unchanged.isEmpty)
    }

    @Test("a failure is reported once per started sign-in")
    func signInFailure() {
        var state = AccountAnalyticsState()
        let unstarted = state.observe(userID: nil, isSettling: false, failure: .timedOut)
        state.signInStarted()
        let failed = state.observe(userID: nil, isSettling: false, failure: .timedOut)
        let repeated = state.observe(userID: nil, isSettling: false, failure: .timedOut)
        #expect(unstarted.isEmpty)
        #expect(failed == [.signInFailed(.timedOut)])
        #expect(repeated.isEmpty)
        #expect(AccountAnalyticsState.reason(.unknown) == .network)
        #expect(AccountAnalyticsState.reason(nil) == nil)
    }
}

@MainActor
@Suite("Machine create analytics", .serialized)
struct MachineCreateAnalyticsTests {
    @Test("a refused create reports its plan limit, and the retry that succeeds reports one create")
    func refusalThenRetry() async throws {
        let (analytics, sink, ledgerSuite) = TestAnalytics.make()
        defer { TestAnalytics.remove(ledgerSuite) }
        let launches = MachineCreateCoordinatorTests.LaunchRecorder()
        let coordinator = MachineCreateCoordinator(
            notifier: { _ in },
            notificationCenter: NotificationCenter(),
            analytics: analytics
        )
        coordinator.start(MachineCreateCoordinatorTests.newMachineRequest(), launch: launches.launch)
        let id = try #require(coordinator.operations.first?.id)
        launches.complete(status: 1, output: "Error: limit", refusalCode: "vm_active_limit_exceeded")
        #expect(coordinator.retry(id))
        launches.complete(status: 0, output: "OK machine=m1", machineID: "m1")
        await analytics.drain()

        let failed = sink.named("cmux_cloud_machine_create_failed")
        #expect(failed.count == 1)
        #expect(failed.first?["error_code"] == .string("vm_active_limit_exceeded"))
        #expect(failed.first?["error_class"] == .string("plan_limit"))
        #expect(sink.named("cmux_cloud_plan_limit_hit").compactMap { $0["limit"] } == [AnalyticsValue.string("active_machines")])
        #expect(sink.named("cmux_cloud_machine_create_succeeded").count == 1)
    }
}
