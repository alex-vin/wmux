import AppKit
import Foundation
import Observation

/// Native Simulator location & camera cleanup ownership shims for wmux
public struct SimulatorLocationOwnershipScope: Sendable {
    public init() {}
    public init(ownershipDirectory: URL, recoveryDirectory: URL) {}
}

public struct SimulatorCameraCleanupOwnershipScope: Sendable {
    public init() {}
    public init(directory: URL) {}
    public func waitForPendingCleanup() async -> Bool { true }
    public func cancelPendingCleanupAndWait(timeout: DispatchTimeInterval = .seconds(5)) async -> Bool { true }
}

/// App-level panel stub for Simulator session in wmux.
/// Simulator functionality is disabled in local lightweight wmux builds.
@MainActor
@Observable
final class SimulatorPanel: Panel {
    static func beginApplicationTerminationCleanup() -> [Task<Void, Never>] {
        []
    }

    static func cancelApplicationTerminationCleanup() {}

    let id = UUID()
    let stableSurfaceIdentity = PanelStableSurfaceIdentity()
    let panelType: PanelType = .simulator

    let preferredDeviceID: String?
    let preferredRuntimeIdentifier: String?
    let preferredDeviceTypeIdentifier: String?
    let requiresExplicitDeviceSelection: Bool

    var isFeatureDisabled: Bool { true }
    var isFeatureReady: Bool { false }

    var displayTitle: String {
        String(localized: "simulator.pane.title", defaultValue: "Simulator")
    }

    var displayIcon: String? { "iphone" }

    var selectedDeviceID: String? { nil }
    var selectedRuntimeIdentifier: String? { nil }
    var selectedDeviceTypeIdentifier: String? { nil }
    var selectedDeviceName: String? { nil }
    var selectedDeviceState: String? { nil }

    init(
        preferredDeviceID: String? = nil,
        preferredRuntimeIdentifier: String? = nil,
        preferredDeviceTypeIdentifier: String? = nil,
        requiresExplicitDeviceSelection: Bool = false
    ) {
        self.preferredDeviceID = preferredDeviceID
        self.preferredRuntimeIdentifier = preferredRuntimeIdentifier
        self.preferredDeviceTypeIdentifier = preferredDeviceTypeIdentifier
        self.requiresExplicitDeviceSelection = requiresExplicitDeviceSelection
    }

    func setVisibleInUI(_ visible: Bool) {}
    func setVisibleInUI(_ visible: Bool, hostID: UUID) {}
    func setMobileFrameDemand(_ active: Bool, consumerID: UUID) {}
    func setCanvasRendering(_ rendering: Bool?) {}

    func close() {}
    func closeAndWait() async {}

    func focus() {}
    func unfocus() {}

    func setFocusOwnershipView(_ view: NSView) {}
    func clearFocusOwnershipView(_ view: NSView) {}

    func ownedFocusIntent(for responder: NSResponder, in window: NSWindow) -> PanelFocusIntent? {
        nil
    }

    func yieldFocusIntent(_ intent: PanelFocusIntent, in window: NSWindow) -> Bool {
        false
    }

    func triggerFlash(reason: WorkspaceAttentionFlashReason) {
        _ = reason
    }
}
