import Foundation
import Testing

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite(.serialized)
struct WmuxMainStartupTests {
    /// Verifies the policy helper defaults to fatal while preserving overrides.
    @Test
    func exceptionCrashPolicyDefaultsToFatalAndPreservesExplicitOverrides() throws {
        let suiteName = "WmuxMainStartupTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        WmuxMain.installCrashOnExceptionsPolicy(defaults: defaults)
        #expect(defaults.bool(forKey: "NSApplicationCrashOnExceptions"))

        defaults.set(false, forKey: "NSApplicationCrashOnExceptions")
        WmuxMain.installCrashOnExceptionsPolicy(defaults: defaults)
        #expect(!defaults.bool(forKey: "NSApplicationCrashOnExceptions"))
    }

    /// Verifies production startup observes the fatal policy before workers or the app.
    @Test
    func productionStartupInstallsPolicyBeforeWorkerAndApp() throws {
        let suiteName = "WmuxMainStartupTests.\(UUID().uuidString)"
        let defaults = try #require(RecordingCrashPolicyDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var observations: [String] = []
        WmuxMain.runStartup(
            defaults: defaults,
            raiseFileDescriptorLimit: {},
            writeAppHostReceipt: {},
            routeWorkers: {
                #expect(defaults.didRegisterFatalPolicy)
                #expect(defaults.bool(forKey: "NSApplicationCrashOnExceptions"))
                observations.append("worker")
            },
            preloadSigningSecret: {},
            launchApp: {
                #expect(defaults.didRegisterFatalPolicy)
                #expect(defaults.bool(forKey: "NSApplicationCrashOnExceptions"))
                observations.append("app")
            }
        )

        #expect(observations == ["worker", "app"])
    }
}

private final class RecordingCrashPolicyDefaults: UserDefaults {
    private(set) var didRegisterFatalPolicy = false

    /// Records this invocation's policy registration independently of Foundation's global registration domain.
    override func register(defaults registrationDictionary: [String: Any]) {
        if registrationDictionary["NSApplicationCrashOnExceptions"] as? Bool == true {
            didRegisterFatalPolicy = true
        }
        super.register(defaults: registrationDictionary)
    }
}
