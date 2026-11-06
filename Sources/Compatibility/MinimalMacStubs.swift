//
//  MinimalMacStubs.swift
//  wmux
//
//  Null stubs and legacy typealiases for macOS-only minimal build.
//

import Foundation
import AppKit
import SwiftUI
import Bonsplit
import WmuxFoundation
import WmuxTerminal
import WmuxBrowser
@_spi(WmuxHostTransport) import WmuxSidebar
@_spi(WmuxHostTransport) import WmuxExtensionKit
import WmuxCore
import WmuxControlSocket
import WmuxSurfaceCatalogModel
import WmuxProductAnalytics
import WmuxSettings
import WmuxCloud
import WmuxCloudTui
import WMUXMobileCore

// MARK: - Disambiguation Typealiases

typealias TerminalWorkContext = WmuxFoundation.TerminalWorkContext

typealias CmuxSidebarSnapshot = WmuxSidebarSnapshot
typealias CmuxSidebarAction = WmuxSidebarAction
typealias CmuxSidebarActionResult = WmuxSidebarActionResult
typealias CmuxExtensionScope = WmuxExtensionScope
typealias CmuxExtensionActionScope = WmuxExtensionActionScope
typealias CmuxExtensionManifest = WmuxExtensionManifest
typealias CmuxFeatureFlags = WmuxFeatureFlags
typealias CmuxFeatureFlagDefinition = WmuxFeatureFlagDefinition
typealias CmuxSurfaceTabBarBuiltInAction = WmuxSurfaceTabBarBuiltInAction
typealias CmuxSidebarWorkspace = WmuxSidebarWorkspace
typealias CmuxExtensionAPIVersion = WmuxExtensionAPIVersion
typealias CloudTerminalReconnectOverlayView = NSView

typealias CMUXSidebarHostXPC = WMUXSidebarHostXPC
typealias CMUXSidebarExtensionXPC = WMUXSidebarExtensionXPC
typealias CMUXSidebarExtensionHostView = WMUXSidebarExtensionHostView
typealias CmuxSidebarExtensionPoint = WmuxSidebarExtensionPoint
typealias CmuxSidebarXPCCodec = WmuxSidebarXPCCodec

typealias CmuxSystemSymbolImage = WmuxSystemSymbolImage

typealias CMUXSidebarExtensionBrowserPresenter = WMUXSidebarExtensionBrowserPresenter
typealias CmuxTuiSurfaceProviderRegistry = WmuxTuiSurfaceProviderRegistry
typealias CloudWorkspaceLayoutSyncCoordinator = CloudTerminalLayoutCoordinator

extension WmuxSidebarXPCCodec {
    public static func decodeManifest(_ data: Data?) throws -> WmuxExtensionManifest {
        guard let data else { throw NSError(domain: "wmux.extension", code: 1) }
        return try decodeManifest(data as NSData)
    }
}

// MARK: - Minimal Remote Proxy Broker

struct FakeCommitLease: ControlRemotePTYLifecycleCommitLease, Sendable {
    func beginReadinessDelivery() -> ControlRemotePTYReadinessDeliveryAdmission { .acquired }
    func finishReadinessDelivery(succeeded: Bool) {}
    @MainActor
    func commitIfCurrent(_ operation: @MainActor @Sendable () -> Bool) -> Bool {
        operation()
    }
}

struct PTYLifecycleOwnerSnapshot: Sendable {
    var transportKey: String = ""
    var attachmentID: String = ""
    var commitLease: any ControlRemotePTYLifecycleCommitLease = FakeCommitLease()
}

struct RemotePTYLifecycleWrapperEndOwner: Sendable {
    var attachmentID: String = ""
}

struct RemotePTYClaimResult: Sendable {
    var wasCurrent: Bool = false
    var transportKey: String = ""
}

protocol RemoteProxyBrokering: AnyObject, Sendable {
    func currentPTYLifecycleOwner(sessionID: String, lifecycleID: String) -> PTYLifecycleOwnerSnapshot?
    func currentPTYLifecycleOwner(_ args: Any...) -> PTYLifecycleOwnerSnapshot?
    func claimPTYLifecycleAfterWrapperEnd(sessionID: String, lifecycleID: String, expectedOwner: Any?) -> RemotePTYClaimResult?
    func claimPTYLifecycleAfterWrapperEnd(_ args: Any...) -> Any?
    func ptyLifecycleOwnerForWrapperEnd(sessionID: String, lifecycleID: String) -> RemotePTYLifecycleWrapperEndOwner?
    func ptyLifecycleOwnerForWrapperEnd(_ args: Any...) -> Any?
}

final class MinimalRemoteProxyBroker: RemoteProxyBrokering, @unchecked Sendable {
    init() {}
    func currentPTYLifecycleOwner(sessionID: String, lifecycleID: String) -> PTYLifecycleOwnerSnapshot? { nil }
    func currentPTYLifecycleOwner(_ args: Any...) -> PTYLifecycleOwnerSnapshot? { nil }
    func claimPTYLifecycleAfterWrapperEnd(sessionID: String, lifecycleID: String, expectedOwner: Any?) -> RemotePTYClaimResult? { nil }
    func claimPTYLifecycleAfterWrapperEnd(_ args: Any...) -> Any? { nil }
    func ptyLifecycleOwnerForWrapperEnd(sessionID: String, lifecycleID: String) -> RemotePTYLifecycleWrapperEndOwner? { nil }
    func ptyLifecycleOwnerForWrapperEnd(_ args: Any...) -> Any? { nil }
}

// MARK: - Legacy Cloud & Remote Types

protocol RemotePTYBridgeStrings: Sendable {
    var missingPersistentPTYCapability: String { get }
    var sessionEnded: String { get }
    var inputBackedUp: String { get }
    var daemonTimeout: String { get }
    func allocationDiagnostic(_ message: String) -> String
    var attachFailed: String { get }
}

struct AppRemotePTYBridgeStrings: RemotePTYBridgeStrings {
    init() {}
    var missingPersistentPTYCapability: String { "" }
    var sessionEnded: String { "" }
    var inputBackedUp: String { "" }
    var daemonTimeout: String { "" }
    func allocationDiagnostic(_ message: String) -> String { message }
    var attachFailed: String { "" }
}

struct RemoteDaemonStrings: Sendable, Equatable {
    static let appLocalized = RemoteDaemonStrings()
    init() {}
}

struct RemoteSessionStrings: Sendable {
    static let appLocalized = RemoteSessionStrings()
    var controlMasterOwnershipUnavailable: String { "" }
    init() {}
}

final class CloudPlacementCoordinator: @unchecked Sendable {
    init() {}
    init(environment: Any? = nil) {}
    init(
        binding: ((UUID) -> WorkspaceCloudVMBinding?)? = nil,
        workspaceExists: ((SurfaceMachineID, String) -> Bool?)? = nil,
        reportFailure: ((SurfaceProjection, any Error) -> Void)? = nil
    ) {}
    init(_ args: Any...) {}
    func confirmPlacement(_ placement: Any? = nil, on machine: Any? = nil, _ args: Any...) {}
    func projectionInCurrentWorkspace(forPanel panelID: UUID? = nil, _ args: Any...) -> SurfaceProjection {
        SurfaceProjection(resource: SurfaceResourceID(machine: .local, kind: .terminal, key: "stub"), workspaceID: UUID(), panelID: panelID ?? UUID())
    }
    func projectionInCurrentWorkspace(_ projection: SurfaceProjection, _ args: Any...) -> SurfaceProjection {
        projection
    }
    func projectionInCurrentWorkspace(_ args: Any...) -> SurfaceProjection {
        SurfaceProjection(resource: SurfaceResourceID(machine: .local, kind: .terminal, key: "stub"), workspaceID: UUID(), panelID: UUID())
    }
    func projectionDidMove(_ projection: Any? = nil, to destination: Any? = nil, catalog: Any? = nil, _ args: Any...) {}
    func projectionDidMove(_ args: Any...) {}
    func projectionDidEnd(_ projection: Any? = nil, reason: Any? = nil, catalog: Any? = nil, _ args: Any...) {}
    func projectionDidEnd(panelID: UUID? = nil, reason: Any? = nil, catalog: Any? = nil, _ args: Any...) {}
    func projectionDidEnd(_ args: Any...) {}
    func restoredProjection(_ record: Any? = nil, workspaceID: UUID? = nil, catalog: Any? = nil, _ args: Any...) -> SurfaceProjection {
        if let proj = record as? SurfaceProjection { return proj }
        return SurfaceProjection(resource: SurfaceResourceID(machine: .local, kind: .terminal, key: "stub"), workspaceID: workspaceID ?? UUID(), panelID: UUID())
    }
    func restoredProjection(_ args: Any...) -> SurfaceProjection {
        SurfaceProjection(resource: SurfaceResourceID(machine: .local, kind: .terminal, key: "stub"), workspaceID: UUID(), panelID: UUID())
    }
    func resolvingLocalPreviewMembership(_ projection: SurfaceProjection, catalog: Any? = nil, _ args: Any...) -> SurfaceProjection { projection }
    func resolvingLocalPreviewMembership(_ args: Any...) -> Any? { nil }
}

final class CloudWorkspaceProjectionCoordinator: @unchecked Sendable {
    struct Environment {
        init(workspaces: Any? = nil) {}
    }
    var environment: Environment = .init()
    init(environment: Environment = .init()) {
        self.environment = environment
    }
    init() {}
    func cancel(machine: Any? = nil) {}
    func request(machine: Any? = nil, catalog: Any? = nil) {}
    func cancel(_ args: Any...) {}
    func request(_ args: Any...) {}
    func retainsProjection(_ args: Any...) -> Bool { true }
    func retainsProjection(_ projection: Any? = nil, in state: Any? = nil, catalog: Any? = nil, _ args: Any...) -> Bool { true }
    func beginLocalMutation(on machine: Any? = nil, _ args: Any...) -> Any? { nil }
    func endLocalMutation(_ token: Any? = nil, on machine: Any? = nil, catalog: Any? = nil, _ args: Any...) {}
}

struct CloudWorkspaceCreationOperation: Sendable {
    var receipt: SurfaceWorkspaceCreationReceipt? = nil
    var reservation: CloudTerminalPaneReservation? = nil
    var machine: SurfaceMachineID = .local
}

final class CloudWorkspaceCreationCoordinator: @unchecked Sendable {
    var operations: [UUID: CloudWorkspaceCreationOperation] = [:]
    init(catalog: Any? = nil) {}
    init(_ args: Any...) {}
    func create(_ args: Any...) {}
    func cancel(machine: SurfaceMachineID? = nil, workspaceID: String? = nil, _ args: Any...) {}
    func cancelAll() {}
    func reconcile(_ args: Any...) {}
    func projectionDidEnd(panelID: UUID? = nil, reason: Any? = nil, _ args: Any...) {}
    func projectionDidEnd(_ args: Any...) {}
}

final class CloudWorkspaceDeletionCoordinator: @unchecked Sendable {
    init(_ args: Any...) {}
    func delete(_ args: Any...) {}
}

final class CloudPortDiscoveryCoordinator: @unchecked Sendable {
    init(_ args: Any...) {}
    func discover(_ args: Any...) {}
}

public enum RemoteDropUploadError: Error, Sendable, Equatable {
    case unavailable
    case invalidFileURL
    case uploadFailed(String)
}

var managedDevicePolicy: ManagedDevicePolicy { ManagedDevicePolicy() }

struct RemotePasteFileTransferPolicy: Equatable, Sendable {
    init(_ args: Any...) {}
    func remotePath(for url: URL? = nil, homeDirectory: String? = nil, _ args: Any...) -> String { url?.path ?? "" }
    func maintenanceScript(_ args: Any...) -> String { "true" }
    func remoteHomeDirectory(fromMaintenanceOutput output: String? = nil, _ args: Any...) -> String? { "/tmp" }
    func finalizeScript(for remotePath: String? = nil, _ args: Any...) -> String { "true" }
    func cleanupScript(for remotePaths: [String] = [], _ args: Any...) -> String { "true" }
}

enum CloudMachinesFeature {
    static var isEnabled: Bool { false }
    static var isAvailable: Bool { false }
    static var disabledMessage: String { "Cloud machines are disabled." }
    static func offMainIsEnabled() -> Bool { false }
}

struct MobilePairingStatusSnapshot: Equatable, Sendable {
    var isRunning: Bool = false
    var configuredPort: Int = 0
    var boundPort: Int = 0
    var usesEphemeralFallback: Bool = false
    var activeConnectionCount: Int = 0
    var routes: [String] = []
    var pendingPortChange: Bool = false
    init(
        isRunning: Bool = false,
        configuredPort: Int = 0,
        boundPort: Int = 0,
        usesEphemeralFallback: Bool = false,
        activeConnectionCount: Int = 0,
        routes: [String] = [],
        pendingPortChange: Bool = false
    ) {
        self.isRunning = isRunning
        self.configuredPort = configuredPort
        self.boundPort = boundPort
        self.usesEphemeralFallback = usesEphemeralFallback
        self.activeConnectionCount = activeConnectionCount
        self.routes = routes
        self.pendingPortChange = pendingPortChange
    }
}

public enum MobilePairingPortApplyResult: Sendable {
    case savedForLater(port: Int)
    case applied(port: Int)
}

enum CmxAttachTransportKind: Sendable {
    case tailscale
    case debugLoopback
    case iroh
    case websocket
}

protocol CloudTuiCommandRunning: Sendable {}

public struct CloudTuiLinkStatus: Sendable {
    public var state: SurfaceLinkState = .error
    public var error: String? = nil
    public init(state: SurfaceLinkState = .error, error: String? = nil) {
        self.state = state
        self.error = error
    }
}

public protocol RemoteTuiLinkManaging: Sendable {
    func connected(machineID: String) async throws -> CloudMachineLink.Connected
    func link(machineID: String) async -> CloudMachineLink?
    func status(machineID: String) async -> CloudTuiLinkStatus?
    func browserProxy(machineID: String) async throws -> Any?
    func browserProxy(_ args: Any...) async throws -> Any?
    func setPrivateAddresses(_ addresses: [String], for machineID: String) async
    func setPrivateAddresses(_ args: Any...)
}

extension CloudMachineLinkManager: @retroactive RemoteTuiLinkManaging {
    nonisolated public func browserProxy(machineID: String = "") async throws -> Any? { nil }
    nonisolated public func browserProxy(_ args: Any...) async throws -> Any? { nil }
    nonisolated public func setPrivateAddresses(_ addresses: [String] = [], for machineID: String = "", _ args: Any...) {}
    nonisolated public func setPrivateAddresses(_ args: Any...) {}
    nonisolated public func status(machineID: String) async -> CloudTuiLinkStatus? { nil }
}

// MARK: - File Explorer Stubs

public struct CloudFileExplorerCommandResult: Sendable {
    public var exitCode: Int32 = 0
    public var stdout: String = ""
    public var stderr: String = ""
    public init(exitCode: Int32 = 0, stdout: String = "", stderr: String = "") {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

protocol CloudFileExplorerCommandRunning: Sendable {
    func run(vmID: String, command: String, timeoutMs: Int) async throws -> CloudFileExplorerCommandResult
}

struct LiveCloudFileExplorerCommandRunner: CloudFileExplorerCommandRunning, Sendable {
    init(target: Any? = nil, _ args: Any...) {}
    init() {}
    func run(vmID: String, command: String, timeoutMs: Int) async throws -> CloudFileExplorerCommandResult {
        CloudFileExplorerCommandResult()
    }
}

public actor CloudFilePreviewCache {
    public static let shared = CloudFilePreviewCache()
    public init() {}
    public func lease(for path: String) -> Any? { nil }
    public func invalidate(for path: String) {}
    public func release(_ args: Any...) {}
    public func refresh(_ lease: Any? = nil, provider: Any? = nil, _ args: Any...) async throws {}
    public func refresh(_ args: Any...) async throws {}
    func materialize(path: String, provider: Any? = nil, _ args: Any...) async throws -> CloudFilePreviewLease {
        CloudFilePreviewLease(url: URL(fileURLWithPath: path), remotePath: path, remoteIdentity: "", cache: self)
    }
}

final class RemoteTerminalFilePreviewCoordinator: @unchecked Sendable {
    init(defaults: UserDefaults = .standard, transport: Any? = nil, cacheDirectory: URL? = nil) {}
    init(_ args: Any...) {}
    func openPreview(_ args: Any...) -> Bool { false }
    func open(workspace: Any? = nil, sourcePanelID: Any? = nil, tokens: Any? = nil, _ args: Any...) -> Bool { false }
    func open(_ args: Any...) -> Bool { false }
}

// MARK: - Mobile Phone Push Settings

public struct MobilePhonePushSettingsSnapshot: Equatable, Sendable {
    public enum Mode: String, CaseIterable, Hashable, Sendable {
        case onlyWhenAway, always
    }
    public let forwardingEnabled: Bool
    public let mode: Mode
    public let hideContent: Bool
    public init(forwardingEnabled: Bool = false, mode: Mode = .always, hideContent: Bool = false) {
        self.forwardingEnabled = forwardingEnabled
        self.mode = mode
        self.hideContent = hideContent
    }
}

public enum MobilePhonePushSettingsMutation: Sendable {
    case forwardingEnabled(Bool)
    case mode(MobilePhonePushSettingsSnapshot.Mode)
    case hideContent(Bool)
}

// MARK: - Remote Tui Machine & Placement

enum RemoteTuiMachine: Sendable {
    case cloud(VMSummary)
    case ssh(Any)

    var id: String { machine.rawValue }
    var defaultTerminalCommand: [String] { [] }

    var machine: SurfaceMachineID {
        switch self {
        case .cloud(let summary):
            return SurfaceMachineID(rawValue: summary.id)
        case .ssh:
            return SurfaceMachineID(rawValue: "ssh")
        }
    }

    var cloudSummary: VMSummary? {
        if case .cloud(let summary) = self { return summary }
        return nil
    }

    var preferredName: String { cloudSummary?.preferredName ?? "ssh" }
    var status: String { cloudSummary?.status ?? "running" }
    var provider: String { cloudSummary?.provider ?? "ssh" }
    var image: String { cloudSummary?.image ?? "" }
    var resolvedKind: WmuxSurfaceCatalogModel.VMMachineKind { cloudSummary?.resolvedKind ?? .base }
    var preferredPrivateAddress: String? { machine.isSSH ? "127.0.0.1" : cloudSummary?.preferredPrivateAddress }
    var capabilities: WmuxCloud.VMCapabilities {
        cloudSummary?.capabilities ?? WmuxCloud.VMCapabilities(snapshot: false, restore: false, fork: false, exec: true, stats: false, ports: true, desktop: false, sizing: false, persistentHome: true, attachTransports: ["ssh"])
    }
}

struct CloudMachineLoadingReservation: Sendable {
    var panelID: UUID = UUID()
    var workspaceID: UUID = UUID()
    var machineID: String = ""

    init(panelID: UUID = UUID(), workspaceID: UUID = UUID(), machineID: String = "", loadingPanel: Any? = nil) {
        self.panelID = panelID
        self.workspaceID = workspaceID
        self.machineID = machineID
    }

    init?(_ resourceID: SurfaceResourceID? = nil, at destination: SurfaceDestination? = nil, remoteView: SurfaceRemoteView? = nil, panelID: UUID = UUID(), workspaceID: UUID = UUID(), machineID: String = "") {
        guard let dest = destination else { return nil }
        self.panelID = panelID
        self.workspaceID = dest.workspaceID
        self.machineID = resourceID?.machine.rawValue ?? machineID
    }

    func loadingPanel(at destination: Any? = nil, machineID: String? = nil, _ args: Any...) throws -> Any? { nil }

    static func withCurrent<T>(_ reservation: CloudMachineLoadingReservation?, _ body: () async throws -> T) async throws -> T {
        try await body()
    }
}

struct CloudDisplayPaneReservation: Sendable {
    var resource: Any?
    var workspaceID: UUID
    var panelID: UUID
    init(resource: Any? = nil, workspaceID: UUID = UUID(), panelID: UUID = UUID()) {
        self.resource = resource
        self.workspaceID = workspaceID
        self.panelID = panelID
    }
    static func withCurrent<T>(_ reservation: CloudDisplayPaneReservation, _ body: () async throws -> T) async throws -> T {
        try await body()
    }
}

struct CloudBrowserCreationPlan {
    var route: String? = nil
    var unavailable: Bool = false
    var unsupportedURL: Bool = false
    var suppressInitialNavigation: Bool = false
    init(route: String? = nil, unavailable: Bool = false, unsupportedURL: Bool = false, suppressInitialNavigation: Bool = false) {
        self.route = route
        self.unavailable = unavailable
        self.unsupportedURL = unsupportedURL
        self.suppressInitialNavigation = suppressInitialNavigation
    }
}

struct CloudPaneCreationFailurePresentation: ViewModifier {
    init(failureStore: Any? = nil, isWorkspaceVisible: Bool = false, sourceView: Any? = nil) {}
    init(_ args: Any...) {}
    func body(content: Content) -> some View { content }
}

final class CloudOptimisticInputRelay: @unchecked Sendable {
    init(_ args: Any...) {}
    func beginRemoteBinding(_ args: Any...) -> UInt64? { 1 }
    func discard() {}
    func send(_ args: Any...) {}
    func setRemoteRebinder(_ args: Any...) {}
    func remoteBindingFailed(token: UInt64? = nil, _ args: Any...) {}
    func bindRemoteTerminal(terminalID: String? = nil, sender: Any? = nil, token: UInt64? = nil, _ args: Any...) -> Bool { true }
    func bindRemoteTerminal(_ args: Any...) -> Bool { true }
}

struct CloudTerminalSourcePlacementStub: Sendable {
    func validate(created: Any? = nil, _ args: Any...) throws {}
}

struct CloudTerminalPaneReservation: Sendable {
    var panelID: UUID = UUID()
    var workspaceID: UUID = UUID()
    var inputRelay: CloudOptimisticInputRelay = CloudOptimisticInputRelay()
    var sourcePlacement: CloudTerminalSourcePlacementStub = CloudTerminalSourcePlacementStub()
    var remoteWorkspaceID: String? = nil
    var machine: SurfaceMachineID = .local

    init(
        panelID: UUID = UUID(),
        workspaceID: UUID = UUID(),
        inputRelay: CloudOptimisticInputRelay = CloudOptimisticInputRelay(),
        sourcePlacement: Any? = nil,
        remoteWorkspaceID: String? = nil,
        machine: SurfaceMachineID = .local
    ) {
        self.panelID = panelID
        self.workspaceID = workspaceID
        self.inputRelay = inputRelay
        self.sourcePlacement = (sourcePlacement as? CloudTerminalSourcePlacementStub) ?? CloudTerminalSourcePlacementStub()
        self.remoteWorkspaceID = remoteWorkspaceID
        self.machine = machine
    }
}

final class CloudPaneCreationFailureStore: @unchecked Sendable {
    init(_ args: Any...) {}
    func present(
        machine: Any? = nil,
        error: Any? = nil,
        requestID: Any? = nil,
        title: Any? = nil,
        recoveryText: Any? = nil,
        sourcePanelID: Any? = nil,
        _ args: Any...
    ) {}
    func beginRequest() -> UUID { UUID() }
    func failRequest(_ args: Any...) {}
    func dismiss(_ args: Any...) {}
    func cancelAll() {}
}

struct SurfaceWorkspaceCreationReceipt: Sendable {
    var workspace: SurfaceRemoteWorkspace = .init(id: "stub", name: "stub", index: 0, focused: false)
    var terminal: Any? = nil
    var cursor: Any? = nil
    init(workspace: SurfaceRemoteWorkspace = .init(id: "stub", name: "stub", index: 0, focused: false), terminal: Any? = nil, cursor: Any? = nil) {
        self.workspace = workspace
        self.terminal = terminal
        self.cursor = cursor
    }
}

final class CloudTerminalLayoutCoordinator: @unchecked Sendable {
    init(_ args: Any...) {}
    func machineLayoutApplied(workspaceID: UUID? = nil, tree: Any? = nil, _ args: Any...) {}
    func machineLayoutApplied(_ args: Any...) {}
    func layoutDidChange(workspaceID: Any? = nil, machine: Any? = nil, remoteWorkspaceID: Any? = nil, catalog: Any? = nil, _ closure: (() -> Any?)? = nil, _ args: Any...) {}
    func layoutDidChange(_ args: Any...) {}
}

@MainActor
final class CloudMachinePinStore: @unchecked Sendable {
    init(_ args: Any...) {}
}

public struct CloudWorkspaceSelection: Sendable {
    public var workspaceID: UUID
    public var scopeID: String
    public var machineID: String
    public init(workspaceID: UUID, scopeID: String, machineID: String) {
        self.workspaceID = workspaceID
        self.scopeID = scopeID
        self.machineID = machineID
    }
}

@MainActor
public final class CloudWorkspaceSelectionState {
    public var revision: UInt64 = 0
    public var trackedWorkspaceID: UUID? { nil }
    public var lastCloudSelection: CloudWorkspaceSelection? { nil }
    public init(scopeProvider: @escaping @MainActor () -> String? = { nil }) {}
    public func select(workspaceID: UUID?, machineID: String?) {}
}

@MainActor
final class CloudWorkspaceCoordinator: @unchecked Sendable {
    init(_ args: Any...) {}
    var isAvailable: Bool { false }
    var scopeIdentifier: Any? { nil }
    func makeSelectionState(_ args: Any...) -> CloudWorkspaceSelectionState? { nil }
}

// MARK: - Workspace Extensions

enum RemotePTYRespawnRouting: Sendable {
    case local
    case persistentSSH
    case unsupportedRemote
}

struct RemoteTmuxWindowMirrorStub: Sendable {
    var surfaceIDsInLayoutOrder: [UUID] = []
}

extension Workspace {
    @MainActor
    static func liveWorkspace(id: UUID) -> Workspace? {
        AppDelegate.shared?.tabManagerFor(tabId: id)?.tabs.first { $0.id == id }
    }

    @discardableResult
    func reconnectCloudTerminalSurface(surfaceId: UUID) -> Bool { false }

    var cloudPaneCreationFailureSourceView: NSView? { nil }
    var usesSSHTui: Bool { false }
    var remoteTmuxWindowMirrors: [UUID: RemoteTmuxWindowMirrorStub] { [:] }
    func cancelReservedCloudTerminalPane(panelID: UUID? = nil, _ args: Any...) {}
    func cancelAllReservedCloudTerminalPanes() {}
    func drainPendingRemotePTYSessionCleanups() {}

    func cloudProjectedResource(forPanel panelID: UUID? = nil, catalog: SurfaceCatalog? = nil, _ args: Any...) -> SurfaceResource? { nil }

    func tuiMirrorSession(for surfaceId: UUID? = nil, _ args: Any...) -> CloudTuiManualMirrorSession? { nil }
    func machineOwningSurface(_ surfaceId: UUID) -> SurfaceMachineID? { nil }
    func cloudBrowserCreationPlan(sourcePanelID: UUID? = nil, requestedURL: URL? = nil, creationPolicy: Any? = nil, _ args: Any...) -> CloudBrowserCreationPlan {
        CloudBrowserCreationPlan()
    }
    func applyCloudBrowserCreationPlan(_ plan: Any? = nil, to panel: Any? = nil, _ args: Any...) {}
    func clearCloudPendingCreations() {}
    func failCloudTerminalAttachment() {}
    func notifyRemoteForegroundAuthenticationReady(token: String? = nil, resolvedControlPath: String? = nil, _ args: Any...) -> Bool { false }
    func prepareCloudTerminalAttachment() {}
    func presentCloudRenameFailure(message: String? = nil, _ args: Any...) {}
    func presentCloudRenameFailure(_ args: Any...) {}
    func presentCloudPlacementFailure(_ args: Any...) {}
    func reconnectRemoteConnection(surfaceId: UUID? = nil, _ args: Any...) {}
    func remotePTYRespawnPlan(panelId: UUID? = nil, rawCommand: Any? = nil, remoteWorkingDirectory: Any? = nil, _ args: Any...) -> Any? { nil }
    func remotePTYRespawnPlan(panelId: UUID? = nil, _ args: Any...) -> Any? { nil }
    func remotePTYRespawnRouting(panelId: UUID? = nil, _ args: Any...) -> RemotePTYRespawnRouting { .local }
    func reserveCloudTerminalPane(machine: SurfaceMachineID? = nil, at destination: SurfaceDestination? = nil, focus: Bool = false, attachmentPlacement: Any? = nil, _ args: Any...) -> CloudTerminalPaneReservation? { nil }
    func failReservedCloudTerminalPane(_ reservation: Any? = nil, error: Any? = nil) {}
    func respawnRemotePTYSurface(panelId: UUID? = nil, plan: Any? = nil, rawStartCommand: Any? = nil, focus: Any? = nil, allowTextBoxFocusDefault: Any? = nil, _ args: Any...) -> TerminalPanel? { nil }
    func respawnRemotePTYSurface(_ args: Any...) -> TerminalPanel? { nil }
    func respawnSSHTuiSurface(panelID: UUID? = nil, command: Any? = nil, workingDirectory: String? = nil, tmuxStartCommand: Any? = nil, focus: Bool? = false, allowTextBoxFocusDefault: Bool = true, _ args: Any...) -> TerminalPanel? { nil }
    func transitionRemoteTerminalToDisconnectedPlaceholder() {}
    func cloudMachineLoadingPanel(at destination: Any? = nil, machineID: String? = nil) -> Any? { nil }
    func routeCloudPaneUISplit(from sourcePanelId: UUID? = nil, into newPane: Any? = nil, orientation: Any? = nil, _ args: Any...) -> Bool { false }
    func routeCloudPaneTerminalTab(inPane paneId: Any? = nil, focus: Bool? = false, _ args: Any...) -> Bool { false }
    func routeCloudPaneTerminalSplit(from panelId: UUID? = nil, orientation: Any? = nil, insertFirst: Any? = nil, focus: Any? = nil, _ args: Any...) -> Bool { false }
    func routeCloudPaneTerminalSplit(_ args: Any...) -> Bool { false }
    func rejectCloudTerminalCreation(source: Any? = nil, panelID: UUID? = nil) -> TerminalPanelCreationOutcome { .failed }
    func reserveRestoredCloudTerminalPane(snapshot: Any? = nil, projection: Any? = nil, inPane: Any? = nil, _ args: Any...) -> UUID? { nil }
    func restoreDeviceDisplayPanel(_ snapshot: Any? = nil, in paneId: Any? = nil) -> UUID? { nil }
    func tuiSSHStatusPayload() -> [String: Any] { [:] }
    func acceptsUnownedBrowserURL(_ url: URL?) -> Bool { true }

    func suspendCloudRemoteConfiguration(_ args: Any...) -> Bool { true }
    func configureSSHTuiConnection(_ config: Any? = nil, autoConnect: Bool = false, _ args: Any...) -> Bool { true }
    static func normalizedForegroundAuthToken(_ token: String?) -> String? { token }
    func enqueueRemoteSessionTransition(targetConfiguration: WorkspaceRemoteConfiguration? = nil, shouldStartController: Bool = false, finalCleanup: Bool = false) {}
    func cloudTerminalSourcePlacement(forPanel panelID: UUID) -> CloudTerminalSourcePlacement? { nil }
    func routeCloudPaneTerminalCreate(source: CloudTerminalSourcePlacement, sourcePanelID: UUID?, destination: SurfaceDestination, focus: Bool, splitDirection: SurfaceSplitDirection? = nil, pendingPane: PaneID? = nil, commandOverride: [String]? = nil) -> TerminalPanelCreationOutcome { .failed }
}

extension WorkspaceRemoteConfiguration {
    var managedCloudVMID: String? { nil }
    var routesThroughSSHTui: Bool { false }
    var fileOperationSSHOptions: [String] { [] }
    func scopedToOwnerWorkspace(_ id: UUID) -> WorkspaceRemoteConfiguration { self }
}

// MARK: - Mobile Browser Support

public enum MobileBrowserPanelNativeSignal: Sendable {
    case stateChanged
    case dirty(editableFocused: Bool?)
    case webViewReplaced
    case dialog(Any? = nil)
    case dialogResolved(Any? = nil)
    case closed
}

extension BrowserPanel {
    var owningWorkspaceRoutesThroughSSHTui: Bool { false }
    var cloudResourceForDuplication: SurfaceResourceID? { nil }
    var cloudRestoreURL: URL? { nil }
    func cloudRestoreURL(on url: URL? = nil, _ args: Any...) -> URL? { url }
    var cloudResourceForSession: SurfaceResourceID? { nil }
    var cloudTeamIDForSession: String? { nil }
    var retainsCloudResourceForDuplication: Bool { false }
    func preferredURLStringForSessionSnapshot() -> String? { nil }

    @discardableResult
    func presentMobileBrowserDialog(
        kind: MobileBrowserDialogKind,
        title: String?,
        message: String?,
        host: String?,
        buttons: [MobileBrowserDialogButton],
        textField: MobileBrowserDialogTextField? = nil,
        informational: Bool = false,
        alert: NSAlert? = nil,
        response: ((String, String?) -> Void)? = nil,
        macResponse: ((NSApplication.ModalResponse) -> (String, String?))? = nil,
        cancelButtonID: String? = nil,
        _ args: Any...
    ) -> MobileBrowserDialogEvent {
        MobileBrowserDialogEvent(
            panelID: id.uuidString,
            dialogID: UUID().uuidString,
            kind: kind,
            title: title,
            message: message,
            host: host,
            buttons: buttons,
            textField: textField,
            informational: informational
        )
    }

    func beginInformationalMobileBrowserDialog(
        kind: MobileBrowserDialogKind,
        title: String? = nil,
        message: String? = nil,
        host: String? = nil,
        cancelLabel: String? = nil,
        cancel: (() -> Void)? = nil,
        _ args: Any...
    ) -> MobileBrowserDialogEvent {
        MobileBrowserDialogEvent(
            panelID: id.uuidString,
            dialogID: UUID().uuidString,
            kind: kind,
            title: title,
            message: message,
            host: host,
            buttons: [],
            textField: nil,
            informational: true
        )
    }

    func respondToJavaScriptDialog(accept: Bool = false, text: String? = nil, _ args: Any...) -> MobileBrowserDialogEvent? { nil }
    var pendingJavaScriptDialogs: [Any] { [] }
    func rebindCloudRouteIfNeeded(to url: URL? = nil, _ args: Any...) -> Bool { true }
    func rebindCloudRouteIfNeeded(_ args: Any...) -> Bool { true }

    func presentMobileClientCertificateAlert(_ alert: Any? = nil, webView: Any? = nil, completion: Any? = nil, cancel: Any? = nil, _ args: Any...) {}

    @discardableResult
    func resolveMobileBrowserDialogFromMac(_ dialog: MobileBrowserDialogEvent, action: () -> Void = {}) -> Bool {
        action()
        return true
    }

    func publishMobileBrowserStreamSignal(_ signal: MobileBrowserPanelNativeSignal) {}
    func privateAddressRouteProvider(for url: URL) -> WmuxTuiSurfaceProvider? { nil }

    func mobileBrowserStreamStateDidChange(markDirty: Bool = false) {}
    func mobileBrowserWebViewDidBind() {}
    func clearMobileStreamViewport() {}
    func cancelPendingJavaScriptDialogs() {}
    func sshLoopbackServiceURL(for url: URL? = nil, _ args: Any...) -> URL? { nil }
    func sshLoopbackServiceURL(_ args: Any...) -> URL? { nil }
    func prepareCloudBrowserStore(machineID: String? = nil, _ args: Any...) {}
    func prepareCloudBrowserStore(_ args: Any...) {}
    func configureCloudBrowser(model: Any? = nil, url: Any? = nil, resourceID: Any? = nil, _ args: Any...) {}
    func configureCloudBrowser(_ args: Any...) {}
    func restoreCloudResource(_ resource: Any? = nil, preferredURL: Any? = nil, activate: Any? = nil, _ args: Any...) {}
    func restoreCloudResource(_ args: Any...) {}
    func installCloudDesktopConnectionObserver(on webView: Any? = nil, _ args: Any...) {}
    func installCloudDesktopConnectionObserver(_ args: Any...) {}
    func prepareCloudBrowserNavigation(_ args: Any...) {}
    func leaveCloudResourceForLocalNavigation(_ args: Any...) {}
}

// MARK: - TerminalController & API Support

struct MobileTerminalInputDelivery: Sendable {
    init(_ args: Any...) {}
}

extension TerminalController {
    static func mobileWorkspaceActionKey(_ rawAction: String?) -> String? {
        rawAction?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    static func mobileAllowsWorkspaceAction(_ action: String?) -> Bool { false }
    func openSSHTuiWorkspace(params: [String: Any]) async throws -> TerminalController.V2CallResult { .ok([:]) }
    func tuiSSHSessionAttachResolve(params: [String: Any]) async -> TerminalController.V2CallResult? { nil }
    func tuiSSHSessions(params: [String: Any]) async -> TerminalController.V2CallResult? { nil }
    func closeTuiSSHSession(params: [String: Any]) async -> TerminalController.V2CallResult? { nil }
    func v2MobilePanelArtifactDispatch(method: String, params: [String: Any], executionContext: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
    nonisolated func mergeRemotePTYSessionLists(tui: TerminalController.V2CallResult, legacy: TerminalController.V2CallResult) -> TerminalController.V2CallResult { tui }
    nonisolated func mergeRemotePTYSessionLists(tui: Any?, legacy: Any?) -> TerminalController.V2CallResult { .ok([:]) }
    func mobileInputNotFound(params: Any? = nil) -> V2CallResult { .err(code: "not_found", message: "Not found", data: nil) }
    func mobileInputNotFound(_ msg: String = "") -> V2CallResult { .err(code: "not_found", message: msg, data: nil) }
    func mobileInputAdmissionAnswer(_ delivery: Any? = nil, workspaceID: UUID? = nil, surfaceID: UUID? = nil, _ args: Any...) -> V2CallResult? { nil }
    func mobileInputSuccessPayload(_ dict: [String: Any], acknowledgement: Any? = nil) -> [String: Any] { dict }
    func mobileTerminalScrollResponsePayload(workspaceID: Any? = nil, terminalTarget: Any? = nil, surfaceID: Any? = nil, params: Any? = nil) -> [String: Any] { [:] }
    func mobileInputDelivery(params: Any? = nil, _ args: Any...) -> MobileTerminalInputDelivery? { nil }

    func noteAcceptedAgentInput(surfaceID: UUID? = nil, _ args: Any...) {}
    func noteAcceptedAgentInput(_ args: Any...) {}
    func v2ChatSessionsDump(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }

    nonisolated static func surfaceNewTerminal(
        machine: SurfaceMachineID, command: [String]?, cwd: String?, name: String?,
        remoteWorkspaceID: String?, destination: SurfaceDestination?, focus: Bool
    ) async throws -> [String: Any] { [:] }
}

// MARK: - Mobile Terminal Grid Frame

public struct MobileTerminalRenderGridFrame: Codable, Equatable, Sendable {
    public enum Anchor: String, Codable, Equatable, Sendable {
        case screen
        case viewport
    }

    public struct Cursor: Codable, Equatable, Sendable {
        public var row: Int
        public var column: Int
        public var visible: Bool

        public init(row: Int = 0, column: Int = 0, visible: Bool = true) {
            self.row = row
            self.column = column
            self.visible = visible
        }
    }

    public struct Style: Codable, Equatable, Sendable {
        public var id: Int
        public var faint: Bool

        public init(id: Int = 0, faint: Bool = false) {
            self.id = id
            self.faint = faint
        }
    }

    public struct RowSpan: Codable, Equatable, Sendable {
        public var row: Int
        public var column: Int
        public var styleID: Int
        public var text: String
        public var cellWidth: Int?

        public init(row: Int = 0, column: Int = 0, styleID: Int = 0, text: String = "", cellWidth: Int? = nil) {
            self.row = row
            self.column = column
            self.styleID = styleID
            self.text = text
            self.cellWidth = cellWidth
        }
    }

    public var format: String = "cmux.render-grid.v1"
    public var surfaceID: String = ""
    public var stateSeq: UInt64 = 0
    public var columns: Int = 80
    public var rows: Int = 24
    public var cursor: Cursor? = nil
    public var styles: [Style] = []
    public var rowSpans: [RowSpan] = []

    public init(
        format: String = "cmux.render-grid.v1",
        surfaceID: String = "",
        stateSeq: UInt64 = 0,
        columns: Int = 80,
        rows: Int = 24,
        cursor: Cursor? = nil,
        styles: [Style] = [],
        rowSpans: [RowSpan] = []
    ) {
        self.format = format
        self.surfaceID = surfaceID
        self.stateSeq = stateSeq
        self.columns = columns
        self.rows = rows
        self.cursor = cursor
        self.styles = styles
        self.rowSpans = rowSpans
    }

    public func jsonObject() throws -> [String: Any] { [:] }
}

public struct MobileTerminalRenderGridFrameResult {
    public var frame: MobileTerminalRenderGridFrame
    public var rows: [String] { frame.rowSpans.map(\.text) }
    public init(frame: MobileTerminalRenderGridFrame = MobileTerminalRenderGridFrame()) {
        self.frame = frame
    }
}

extension TerminalSurface {
    func mobileRenderGridFrame(stateSeq: UInt64 = 0, includeTheme: Bool = false, anchor: MobileTerminalRenderGridFrame.Anchor = .screen) -> MobileTerminalRenderGridFrameResult? {
        nil
    }
    func pasteCloudImages(_ urls: [URL] = [], operation: Any? = nil, _ args: Any...) async throws -> Bool { false }
    func pasteCloudImages(_ args: Any...) async throws -> Bool { false }
    func mobileClick(col: Int = 0, row: Int = 0, _ args: Any...) {}
    func mobileScroll(deltaLines: Double = 0, col: Int = 0, row: Int = 0, _ args: Any...) {}
    func mobileScroll(deltaLines: Int, col: Int, row: Int, _ args: Any...) {}
    func mobileScroll(_ args: Any...) {}
}

extension TerminalSurface.TextSendResult {
    var inputSendResult: Any? { nil }
}

final class CloudTerminalOverlayCoordinator: @unchecked Sendable {
    var overlay: NSView? { nil }
    var session: Any? { nil }
    var endedPresentation: Any? { nil }
    init(_ args: Any...) {}
    func update(_ args: Any...) {}
    func updateAnchor(_ host: Any? = nil, visible: Any? = nil, ownershipGeneration: Any? = nil, _ args: Any...) {}
    func updateAnchor(_ args: Any...) {}
    func synchronize(hostedView: Any? = nil, contentFrame: Any? = nil, legacyPresentation: Any? = nil, onReconnect: Any? = nil, _ args: Any...) {}
    func synchronize(_ args: Any...) {}
}

// MARK: - Legacy Providers & Registries

extension WmuxTuiSnapshotParser {
    public static func parseGrid(from data: Data) -> MobileTerminalRenderGridFrame? { nil }
    public static func parseRenderGrid(from data: Data) -> MobileTerminalRenderGridFrame? { nil }
}

extension WmuxTuiSurfaceProvider {
    nonisolated static func portResources(machine: SurfaceMachineID, scannedPorts: [Int]?, previousResources: [SurfaceResource], privateAddress: String?, displayPortsOwned: Bool = false) -> [SurfaceResource] {
        []
    }
    nonisolated static func portScan(
        from result: VMExecResult? = nil,
        privateAddress: String? = nil,
        displayPortsOwned: Bool = false,
        _ args: Any...
    ) -> CloudPortScanResult? {
        nil
    }
    func tuiPortScanResult(
        from result: VMExecResult? = nil,
        privateAddress: String? = nil,
        displayPortsOwned: Bool = false,
        _ args: Any...
    ) -> CloudPortScanResult? {
        nil
    }
    func attachReservedTerminalPane(_ reservation: Any? = nil, resource: SurfaceResource? = nil, remoteTabID: String? = nil, _ args: Any...) {}
    func configureBrowser(_ panel: BrowserPanel, url: URL, request: URLRequest? = nil) {}
    func renameDisplayFromTab(displayID: String, name: String) {}
    func renameDisplay(displayID: String, name: String) async throws {}
}

extension CloudWorkspaceRenameService {
    func reconcileRemoteState(machine: Any? = nil, state: Any? = nil, catalog: Any? = nil, observation: Any? = nil, affectedResources: Any? = nil, workspaceNamesChanged: Any? = nil, _ args: Any...) {}
    func reconcileRemoteState(_ args: Any...) {}
    func reconcileRemoteWorkspaceName(workspace: Any? = nil, machine: Any? = nil, state: Any? = nil, catalog: Any? = nil, observation: Any? = nil, _ args: Any...) {}
    func reconcileRemoteWorkspaceName(_ args: Any...) {}
}

extension String {
    func isPOSIXShellBareWord(punctuation: String) -> Bool { true }
}

public struct RemoteWorkspaceReconnectionPolicy {
    public init(_ args: Any...) {}
    public static let shared = RemoteWorkspaceReconnectionPolicy()
    public func shouldReconnect(_ args: Any...) -> Bool { false }
}

public struct RemoteTerminalTransportError: Error, Sendable {
    public init(_ args: Any...) {}
}

public struct MobileHostDiagnostics {
    public struct Report {
        public func humanReadableExport() -> Data { Data() }
        public init() {}
    }
    public struct Log {
        public func snapshot() async -> Report { Report() }
    }
    public static let log = Log()
}

public struct CmuxRemoteDaemonDiagnostics {
    public struct DiagnosticReport {
        public init() {}
    }
    public struct Log {
        public func snapshot() async -> DiagnosticReport { DiagnosticReport() }
    }
    public static let log = Log()
}

func refuseCloudComposerImage() {}

func mobileInputWriteFailure(code: String = "", message: String = "", surfaceID: UUID? = nil, acknowledgement: Any? = nil, _ args: Any...) -> TerminalController.V2CallResult {
    .err(code: code, message: message, data: nil)
}

func v2MobileChatSend(params: Any? = nil, _ args: Any...) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileChatInterrupt(params: Any? = nil, _ args: Any...) async -> TerminalController.V2CallResult { .ok([:]) }
func v2ChatSessionsDump(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }

func v2RemoteSessionParkedResult(detail: Any?, workspaceId: Any?, workspaceRef: Any?) -> TerminalController.V2CallResult {
    .ok([:])
}
func v2RemoteSessionParkedResult(workspaceId: Any?, params: Any?) -> TerminalController.V2CallResult? {
    nil
}
func v2RemoteSessionParkedResult(_ args: Any...) -> TerminalController.V2CallResult? {
    nil
}

func v2MobileWorkspaceList(params: Any? = nil, tabManager: Any? = nil, createdTerminalID: Any? = nil, createdWorkspaceID: Any? = nil, _ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceList(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceChanges(method: Any? = nil, params: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileDirectorySearch(params: Any? = nil, filesystemJobQuota: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileDirectoryList(params: Any? = nil, filesystemJobQuota: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceCreate(params: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTaskAttachmentUpload(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTaskModelsList(params: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalCreate(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalInput(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalPaste(params: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalPasteImage(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalReplay(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalViewport(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalScroll(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalReattach(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalSizePolicySet(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalParticipantDisconnect(params: Any? = nil, connectionID: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalMouse(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalClose(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalRename(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalArtifactDispatch(method: Any? = nil, params: Any? = nil, executionContext: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTerminalArtifactDispatch(_ args: Any...) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceAction(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceMove(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceGroupCreate(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceGroupAction(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileChatDispatch(method: Any? = nil, params: Any? = nil, executionContext: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileChatDispatch(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileBrowserDispatch(method: Any? = nil, params: Any? = nil, connectionID: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileSimulatorDispatch(method: Any? = nil, params: Any? = nil, connectionID: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileTodoDispatch(method: Any? = nil, params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileSurfaceFocus(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileSurfaceFocus(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobilePanelArtifactDispatch(method: Any? = nil, params: Any? = nil, executionContext: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceClose(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceClose(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceGroupSetCollapsed(params: Any? = nil, isCollapsed: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileWorkspaceGroupSetCollapsed(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationDismiss(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationDismiss(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationReconcile(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationReconcile(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedList(params: Any? = nil, responseID: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedList(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileFeedList(params: Any? = nil, responseID: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileFeedList(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileFeedText(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileFeedText(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkRead(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkRead(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkUnread(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkUnread(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkAllRead(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileNotificationFeedMarkAllRead(_ args: Any...) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileDogfoodFeedbackSubmit(params: Any? = nil) async -> TerminalController.V2CallResult { .ok([:]) }
func v2MobileSyncFetch(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }
func v2MobilePhonePushSettingsUpdate(params: Any? = nil) -> TerminalController.V2CallResult { .ok([:]) }

func acceptsRestoredSession(_ snapshot: Any? = nil, projection: Any? = nil, _ args: Any...) -> Bool { true }
func acceptsRestoredPanel(_ snapshot: Any? = nil, projection: Any? = nil, _ args: Any...) -> Bool { true }
func attachFileURLs(_ urls: [URL], into textView: NSTextView) -> Bool { false }

func publishMobileBrowserStreamSignal(_ args: Any...) {}
func privateAddressRouteProvider(for url: Any? = nil, _ args: Any...) -> Any? { nil }
func enqueueRemoteSessionTransition(_ args: Any...) {}

struct CmuxAccentColor {
    static var builtInAgentStatusHex: String { "#007AFF" }
}

func cancelPendingRemoteControlMasterAdoption(_ args: Any...) {}

struct CurrentCloudWorkspaceResult {
    var group: SurfaceResourceGroup
    var layout: SurfaceProjectionLayout?
}

func currentCloudWorkspace(_ group: SurfaceResourceGroup) throws -> CurrentCloudWorkspaceResult? { nil }
func currentCloudWorkspace(_ args: Any...) -> Any? { nil }

final class ProcessOutputCollector: @unchecked Sendable {
    private let stdout: Pipe?
    private let stderr: Pipe?
    private var data = Data()

    init(stdout: Pipe? = nil, stderr: Pipe? = nil) {
        self.stdout = stdout
        self.stderr = stderr
    }

    init(_ args: Any...) {
        self.stdout = nil
        self.stderr = nil
    }

    func start() {
        if let stdout {
            stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let d = handle.availableData
                if !d.isEmpty { self?.data.append(d) }
            }
        }
        if let stderr {
            stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let d = handle.availableData
                if !d.isEmpty { self?.data.append(d) }
            }
        }
    }

    func finish() -> String {
        stdout?.fileHandleForReading.readabilityHandler = nil
        stderr?.fileHandleForReading.readabilityHandler = nil
        return String(data: data, encoding: .utf8) ?? ""
    }

    func cancel() {
        stdout?.fileHandleForReading.readabilityHandler = nil
        stderr?.fileHandleForReading.readabilityHandler = nil
    }
}

@MainActor
final class CloudVMActionLauncher {
    static let shared = CloudVMActionLauncher()
    static let hiddenOutputPlaceholder = "..."

    struct CancellationHandle {
        private let action: @MainActor () -> Void
        init(_ action: @escaping @MainActor () -> Void = {}) {
            self.action = action
        }
        @MainActor func cancel() { action() }
    }

    struct Completion {
        var terminationStatus: Int32 = 0
        var output: String = ""
        var workspaceId: UUID? = nil
        var machineId: String? = nil
        var wasCancelled: Bool = false
        var refusalCode: String? = nil
        var succeeded: Bool { terminationStatus == 0 }
        var indicatesCloudVMNotFound: Bool {
            !succeeded && output.range(of: "vm_not_found", options: .caseInsensitive) != nil
        }
    }

    init() {}

    @discardableResult
    func start(
        socketPath: String = "",
        preferredWindow: NSWindow? = nil,
        arguments: [String] = [],
        successTitle: String? = nil,
        presentOutputOnSuccess: Bool = false,
        presentsFailureAlert: Bool = true,
        environmentOverrides: [String: String] = [:],
        onCancellationReady: ((CloudVMActionLauncher.CancellationHandle) -> Void)? = nil,
        onOutput: (@MainActor (String) -> Void)? = nil,
        onCompletion: ((CloudVMActionLauncher.Completion) -> Void)? = nil
    ) -> Bool {
        onCompletion?(Completion(terminationStatus: 0, output: "", workspaceId: nil))
        return true
    }

    func cancelAllForAuthTransition(cleanupCreatedMachines: Bool = false) {}

    nonisolated static func sanitizedCloudVMStartOutput(_ output: String) -> String { output }
}

final class SSHTuiWorkspaceCoordinator: @unchecked Sendable {
    init(catalog: Any? = nil, clientURL: Any? = nil, paths: Any? = nil) {}
    init(_ args: Any...) {}
    func disconnect(workspace: Any? = nil) {}
}

final class CloudWorkspaceCreationHost: @unchecked Sendable {
    init(manager: Any? = nil, _ args: Any...) {}
    init(_ args: Any...) {}
}

final class CloudManualMirrorMaterialization: @unchecked Sendable {
    var workspaceID: UUID = UUID()
    var panelID: UUID = UUID()
    var remotePlacement: SurfaceRemotePlacement? = nil
    init(workspaceID: UUID = UUID(), panelID: UUID = UUID(), remotePlacement: SurfaceRemotePlacement? = nil, _ args: Any...) {
        self.workspaceID = workspaceID
        self.panelID = panelID
        self.remotePlacement = remotePlacement
    }
}

extension WmuxTuiSnapshotParser.CreatedTerminalPath {
    init(terminalID: String = "") {
        self.init(
            attachment: nil,
            terminalID: terminalID,
            workspaceID: "stub-workspace",
            screenID: nil,
            paneID: nil,
            tabID: nil,
            cursor: nil
        )
    }
}

struct CloudTerminalLayoutCreationResult: Sendable {
    var created: WmuxTuiSnapshotParser.CreatedTerminalPath = .init(terminalID: "")
    var workspaceID: String = "stub-workspace"
}

final class CloudTerminalLayoutCreation: @unchecked Sendable {
    init(machine: Any? = nil, socketPath: Any? = nil, commandRunner: Any? = nil, initialState: Any? = nil, terminalCommand: Any? = nil, _ args: Any...) {}
    init(_ args: Any...) {}
    func run(nearTabID: Any? = nil, splitDirection: Any? = nil, idempotencyKey: Any? = nil, correlationKey: Any? = nil, expectedWorkspaceID: Any? = nil, _ args: Any...) async throws -> CloudTerminalLayoutCreationResult {
        CloudTerminalLayoutCreationResult()
    }
    func run(_ args: Any...) async throws -> CloudTerminalLayoutCreationResult {
        CloudTerminalLayoutCreationResult()
    }
}

final class CloudNotificationSync: @unchecked Sendable {
    init(_ args: Any...) {}
    func retire() {}
    func linkDidConnect() {}
}

@MainActor
final class CloudSurfaceDropGateView: NSView {
    weak var workspace: Workspace?
    var isActive: Bool = false
    struct Feedback {
        func clear() {}
    }
    let feedback = Feedback()
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

extension DetectedSSHSession {
    init(configuration: WorkspaceRemoteConfiguration) {
        self.init(
            destination: configuration.destination,
            port: configuration.port,
            identityFile: configuration.identityFile,
            configFile: nil,
            jumpHost: nil,
            controlPath: nil,
            useIPv4: false,
            useIPv6: false,
            forwardAgent: false,
            compressionEnabled: false,
            sshOptions: configuration.sshOptions
        )
    }
}

enum SelectCloudTreeLocalWorkspaceOutcome {
    case selected, openInUnfocusableWindow, notOpen
}

extension AppDelegate {
    func selectCloudTreeLocalWorkspace(_ workspaceID: UUID, from tabManager: TabManager) -> SelectCloudTreeLocalWorkspaceOutcome { .notOpen }
    static func makeCloudTerminalNavigationHost() -> Any? { nil }
    @MainActor func makeCloudTunnelCoordinator() -> CloudTunnelCoordinator? { nil }
    @MainActor func cloudTunnelAccessDidEnd() {}
    func prepareRemoteSessionsForSystemSleep() {}
    func rearmRemoteSessionsAfterSystemWake() {}

    @discardableResult
    func performNewCloudWorkspaceOnCurrentMachineAction(
        tabManager: TabManager? = nil,
        preferredWindow: NSWindow? = nil,
        vmID: String? = nil,
        debugSource: String = "newCloudWorkspace",
        destination: Any? = nil
    ) -> Bool { false }

    @discardableResult
    func performNewCloudWorkspaceOnResolvedMachineAction(
        tabManager preferredTabManager: TabManager? = nil,
        preferredWindow: NSWindow? = nil,
        debugSource: String = "newCloudWorkspace",
        destination: Any? = nil
    ) -> Bool { false }

    @discardableResult
    func performNewCloudMachineAction(
        tabManager preferredTabManager: TabManager? = nil,
        event: NSEvent? = nil,
        preferredWindow: NSWindow? = nil,
        debugSource: String = "newCloudMachine",
        destination: Any? = nil
    ) -> Bool { false }
}

extension TabManager {
    func recordCloudWorkspaceSelection(machineID: Any? = nil, _ args: Any...) {}
}

extension SurfaceCatalog {
    func preferredLocalWorkspaceID(for resource: SurfaceResource? = nil, fallback: UUID? = nil, _ args: Any...) async -> UUID? { fallback }
    func preferredLocalWorkspaceID(for resourceID: SurfaceResourceID, fallback: UUID? = nil, _ args: Any...) async -> UUID? { fallback }
    func cloudWorkspaceLayout(machine: Any? = nil, workspaceID: Any? = nil, _ args: Any...) -> SurfaceProjectionLayout? { nil }
    var cloudWorkspaceLayout: Any? { nil }
    func preservingConcurrentPortResources(_ fallback: [SurfaceResource] = [], on machine: SurfaceMachineID? = nil, since: [SurfaceResource] = [], _ args: Any...) -> [SurfaceResource] {
        fallback
    }
    func preservingConcurrentPortResources<T>(_ body: () async throws -> T) async throws -> T {
        try await body()
    }
    func beginProjectionMutation(for ids: [SurfaceResourceID]) -> Any? { nil }
    func endProjectionMutation(_ scope: Any?) {}
    func reconcileCloudProjection(_ projection: SurfaceProjection) {}
    func reconcileCloudRemoteState(machine: Any? = nil, state: Any? = nil, observation: Any? = nil, _ args: Any...) {}
    func reconcileCloudRemoteState(_ args: Any...) {}
    func applyCloudStateResourcePatch(_ state: Any? = nil, resources: Any? = nil, affectedResourceIDs: Any? = nil, info: Any? = nil, observation: Any? = nil, _ args: Any...) -> Bool { true }
    func applyCloudStateResourcePatch(_ args: Any...) -> Bool { true }
    func requestCloudWorkspaceProjection(_ workspaceID: UUID) {}
    nonisolated static func portDestinationUnavailableMessage(machine: SurfaceMachineID) -> String {
        "Destination unavailable for machine \(machine)"
    }
    nonisolated static func portPreviewUnavailableMessage(machineID: String) -> String {
        "Port preview unavailable for machine \(machineID)"
    }
    struct PortOpenResult: Sendable {
        var projection: SurfaceProjection
        var reused: Bool
    }
    func openCloudPort(
        machine: SurfaceMachineID,
        port: Int,
        into destination: SurfaceDestination,
        focus: Bool = false,
        reuseExisting: Bool = false,
        _ args: Any...
    ) async throws -> PortOpenResult {
        let proj = SurfaceProjection(
            resource: SurfaceResourceID(machine: machine, kind: .browser, key: SurfaceResourceID.portKey(port)),
            workspaceID: destination.workspaceID,
            panelID: UUID()
        )
        return PortOpenResult(projection: proj, reused: false)
    }
}

extension wmuxApp {
    static func makeCloudWorkspaceComposition(auth: MacAuthComposition) -> (machinePinStore: CloudMachinePinStore, workspaceCoordinator: CloudWorkspaceCoordinator) {
        return (CloudMachinePinStore(), CloudWorkspaceCoordinator())
    }
}
