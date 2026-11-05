import Foundation

public struct ComputerUseRuntimePaths: Sendable {
    public static let daemonSocketEnvironmentKey = "WMUX_COMPUTER_USE_DAEMON_SOCKET"
    public static let codexDaemonSocketEnvironmentKey = "WMUX_COMPUTER_USE_CODEX_SOCKET"
    public static let stateDirectoryEnvironmentKey = "WMUX_COMPUTER_USE_STATE_DIR"
    public static let runtimeScopeEnvironmentKey = "WMUX_COMPUTER_USE_RUNTIME_SCOPE"
    public static let clientExecutableEnvironmentKey = "WMUX_COMPUTER_USE_CLIENT_EXEC"
    public static let authenticationTokenEnvironmentKey = "WMUX_COMPUTER_USE_AUTH_TOKEN"
    public static let authenticationTokenFileEnvironmentKey = "WMUX_COMPUTER_USE_AUTH_FILE"

    public let daemonSocketURL = URL(fileURLWithPath: "/dev/null")
    public let codexDaemonSocketURL = URL(fileURLWithPath: "/dev/null")
    public let stateDirectoryURL = URL(fileURLWithPath: "/dev/null")
    public let scope = "disabled"
    public let installedHelperExecutableURL = URL(fileURLWithPath: "/dev/null")
    public let authenticationTokenFileURL = URL(fileURLWithPath: "/dev/null")

    public init() {}
}

public final class ComputerUseOnboardingStore: Sendable {
    public func updates() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}

public final class ComputerUseRuntimeService: @unchecked Sendable {
    public let desiredEnabled = false
    public let setupStatusIsKnown = false
    public let permissionStatusIsKnown = false
    public let onboardingIsComplete = false
    public let stateAuthenticationKey = ""
    public let stateDirectoryURL = URL(fileURLWithPath: "/dev/null")
    public let onboarding = ComputerUseOnboardingStore()

    public init(paths: ComputerUseRuntimePaths = ComputerUseRuntimePaths()) {}

    public func refreshHelperStatus() async -> Bool { false }
    public func setEnabled(_ enabled: Bool) async {}
    public func status() -> (accessibility: Bool, screenRecording: Bool) { (false, false) }
}

public final class ComputerUseOnboardingWindowController: Sendable {
    public enum StartingPoint: Sendable {
        case overview
        case accessibility
        case screenRecording
    }
}

public final class ComputerUseStateRepository: Sendable {
    public init(authenticationKey: String = "") {}
}

public final class ComputerUseLiveSettingRepository: Sendable {
    public init(fileURL: URL) {}
}

@MainActor
public final class ComputerUseUXCoordinator {
    public init() {}
    public init(
        liveAgentIndex: Any? = nil,
        stateRepository: Any? = nil,
        stateDirectoryURL: Any? = nil,
        configStore: Any? = nil,
        enabledKey: Any? = nil,
        showInMenuBarKey: Any? = nil,
        liveSettingRepository: Any? = nil,
        runtimeService: Any? = nil,
        userDefaults: UserDefaults = .standard,
        workspaceTitle: Any? = nil,
        featureEnabled: Any? = nil,
        ownsSurface: Any? = nil
    ) {}

    public func presentOnboardingFromSettings(
        startingAt startingPoint: ComputerUseOnboardingWindowController.StartingPoint = .overview
    ) -> Bool {
        false
    }

    public func teardownForTermination() {}
    public func install(
        onFocusSurface: @escaping (UUID, UUID?, @escaping @MainActor @Sendable () -> Bool) -> Void = { _, _, _ in }
    ) {}
}
