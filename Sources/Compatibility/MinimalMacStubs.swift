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

// cleared duplicate CloudWorkspaceCreationCoordinator

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

// protocol CloudTuiCommandRunning: Sendable {}

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

// cleared duplicate CloudMachineLinkManager

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
    public func refresh(_ args: Any...) async {}
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
    var capabilities: VMCapabilities {
        cloudSummary?.capabilities ?? VMCapabilities(snapshot: false, restore: false, fork: false, exec: true, stats: false, ports: true, desktop: false, sizing: false, persistentHome: true, attachTransports: ["ssh"])
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

// MARK: - Comprehensive Minimal macOS Stubs

import WebKit
import Network
import WmuxAgentChat
import WmuxSurfaceCatalogModel
import WmuxFoundation
import WmuxCore
import Foundation
import AppKit

// MARK: 1. System, AppKit & Core Extensions
extension NSNotification.Name {
    public static let cmuxCloudVMAccessDidEnd = NSNotification.Name("cmuxCloudVMAccessDidEnd")
    public static let cmuxCloudReadNetworkRecovered = NSNotification.Name("cmuxCloudReadNetworkRecovered")
}

extension NSPasteboard.PasteboardType {
    public static let cloudSidebarRow = NSPasteboard.PasteboardType("com.cmux.cloudSidebarRow")
}

extension WorkspaceRemoteConfiguration {
    public var targetMachineID: SurfaceMachineID { .local }
}

extension SurfaceResourceID {
    public var uuidString: String { "\\(machine.rawValue):\\(kind.rawValue):\\(key)" }
}

// removed duplicate cloudProcessDisplayTitle

extension SurfaceProjection {
    public var isLocalWorkspaceView: Bool {
        remoteTabID == nil && (resource.kind == .display || resource.isForwardedPort)
    }

    public static func localWorkspaceMembers(resources: [SurfaceResource], projections: [SurfaceProjection]) -> [(resource: SurfaceResource, workspaceID: String)] {
        let previews = Dictionary(
            resources.filter { $0.kind == .display || $0.id.isForwardedPort }.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var seen: [SurfaceResourceID: Set<String>] = [:]
        for resource in resources {
            for workspace in resource.remoteWorkspaces {
                seen[resource.id, default: []].insert(workspace.id)
            }
        }
        return projections.compactMap { projection in
            guard projection.isLocalWorkspaceView,
                  let workspaceID = projection.remoteWorkspaceID,
                  let resource = previews[projection.resource],
                  seen[resource.id, default: []].insert(workspaceID).inserted else { return nil }
            return (resource, workspaceID)
        }
    }
}

// MARK: 2. SSH TUI & Remote Session Infrastructure
public enum RemoteRelayCleanupScope: Sendable, Equatable {
    case persistentSlot
    case workspace
}

public enum RemotePTYSessionLifecycle: String, Sendable, Equatable {
    case active
    case intentionalCleanupRequested = "intentional_cleanup_requested"
    case intentionallyClosed = "intentionally_closed"
}

public enum RemotePTYLifecycleError: Error, Sendable, Equatable {
    case intentionallyClosed
    case attachmentMismatch
    case capacityReached
    case failed
}

public struct RemoteSessionParkedError: Error, Sendable, Equatable {
    public var detail: String = ""
    public init(detail: String = "") { self.detail = detail }
}

public struct RemotePTYBridgeEndpoint: Sendable, Equatable {
    public var host: String = "127.0.0.1"
    public var port: Int = 0
    public var token: String = ""
    public var sessionID: String = ""
    public var lifecycleID: String = ""
    public var attachmentID: String = ""
    public var daemonVersion: String? = nil
    public init(
        host: String = "127.0.0.1",
        port: Int = 0,
        token: String = "",
        sessionID: String = "",
        lifecycleID: String = "",
        attachmentID: String = "",
        daemonVersion: String? = nil
    ) {
        self.host = host; self.port = port; self.token = token
        self.sessionID = sessionID; self.lifecycleID = lifecycleID
        self.attachmentID = attachmentID; self.daemonVersion = daemonVersion
    }
}

public enum RemotePTYBridgeServer {
    public typealias Endpoint = RemotePTYBridgeEndpoint
}

public final class RemotePTYLifecycleCommitLease: @unchecked Sendable {
    public init() {}
    public func commitIfCurrent<Result>(_ operation: () throws -> Result) rethrows -> Result? { try operation() }
    public func withCurrentCommit<Result>(_ operation: () throws -> Result) rethrows -> Result? { try operation() }
}

public enum PortScanKickReason: String, Sendable, Hashable {
    case command
    case refresh
    public var burstOffsets: [Double] { [0.0] }
    public func merged(with other: Self) -> Self { self }
}

public struct NativeSSHControlMasterAdoptionHandoff: Sendable, Equatable {
    public var controlPath: String = ""
    public init(controlPath: String = "") { self.controlPath = controlPath }
}

public final class NativeSSHConnectionBroker: @unchecked Sendable {
    public init() {}
    public func retainWorkspace<T>(_ config: T) -> T { config }
    public func completeControlMasterAdoption(_ args: Any...) -> Bool { true }
    public func completeControlMasterAdoption(_ adoption: Any? = nil, configuration: Any? = nil, _ args: Any...) -> Bool { true }
    public func cancelControlMasterAdoption(_ args: Any...) {}
    public func releaseWorkspace(_ args: Any...) {}
}

public final class RemoteSessionCoordinator: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func start(_ args: Any...) {}
    public func stop(cleanupScope: RemoteRelayCleanupScope = .persistentSlot, _ args: Any...) {}
    public func cancel() {}
    public func uploadDroppedFiles(_ urls: [URL] = [], operation: Any? = nil, _ completion: @escaping (Result<[String], Error>) -> Void = { _ in }) {}
    public func updateRemotePortScanTTYs(_ args: Any...) {}
    public func updateRemotePortScanningEnabled(_ args: Any...) {}
    public func listPTYSessions(timeout: TimeInterval = 8.0, _ args: Any...) throws -> [[String: Any]] { [] }
    public func acknowledgePTYLifecycle(sessionID: String = "", lifecycleID: String = "", _ args: Any...) throws {}
    public func acknowledgePTYLifecycleAfterWrapperEnd(sessionID: String = "", lifecycleID: String = "") -> Bool { true }
    public func ptySessionLifecycle(sessionID: String = "", lifecycleID: String = "") throws -> RemotePTYSessionLifecycle { .active }
    public func closePTYSession(sessionID: String = "", timeout: TimeInterval = 8.0, _ args: Any...) throws {}
    public func detachPTYSession(sessionID: String = "", attachmentID: String = "", attachmentToken: String = "", _ args: Any...) throws {}
    public func resizePTY(sessionID: String = "", attachmentID: String = "", attachmentToken: String = "", cols: Int = 80, rows: Int = 24, _ args: Any...) throws {}
    public func kickRemotePortScan(panelId: UUID? = nil, reason: PortScanKickReason = .command) {}
    public func prepareForSystemSleep() {}
    public func resetReconnectPolicyAndReconnect(reason: String = "") {}
    public func updateRemoteRelayIDAliases(workspaceAliases: [UUID: UUID] = [:], surfaceAliases: [UUID: UUID] = [:], _ args: Any...) {}
    public func startPTYBridge(
        sessionID: String = "",
        lifecycleID: String = "",
        attachmentID: String = "",
        command: String? = nil,
        cwd: String? = nil,
        environment: [String: String] = [:],
        cols: Int = 80,
        rows: Int = 24,
        requireExisting: Bool = false,
        timeout: TimeInterval = 8.0,
        _ args: Any...
    ) throws -> RemotePTYBridgeEndpoint {
        RemotePTYBridgeEndpoint(sessionID: sessionID, lifecycleID: lifecycleID, attachmentID: attachmentID)
    }
    public func startPTYBridge(
        sessionID: String,
        lifecycleID: String,
        attachmentID: String,
        command: String?,
        requireExisting: Bool,
        waitForReady: Bool,
        timeout: TimeInterval
    ) throws -> RemotePTYBridgeEndpoint {
        RemotePTYBridgeEndpoint(sessionID: sessionID, lifecycleID: lifecycleID, attachmentID: attachmentID)
    }
}

public struct RemotePersistentPTYIdentifier: Sendable, Hashable, RawRepresentable {
    public let rawValue: String
    public var value: String { rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String = "") { self.rawValue = rawValue }
    public init(rawName: String = "") { self.rawValue = rawName }
}

public final class RemotePTYRespawnPlanner: @unchecked Sendable {
    public init() {}
    public static func defaultSessionID(workspaceID: UUID = UUID(), panelID: UUID = UUID(), _ args: Any...) -> String { UUID().uuidString }
    public static func defaultSessionID(_ args: Any...) -> String { UUID().uuidString }
}

public final class RemoteProxyBroker: @unchecked Sendable {
    public init() {}
    public var configurationRefresher: (@Sendable (WorkspaceRemoteConfiguration) async -> WorkspaceRemoteConfiguration?)? = nil
}

public struct RemoteRelayAgentHookAdmission: Sendable, Equatable {
    public init() {}
    public func queueParameters(from params: [String: Any]) -> [String: Any]? { params }
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
}

public struct RemoteTmuxKeyName: Equatable, Sendable {
    public let value: String
    public init?(rawName: String) { self.value = rawName }
    public init(_ value: String = "") { self.value = value }
}

public struct SSHTuiConnection: Sendable, Equatable {
    public var id: String = UUID().uuidString
    public var commandArguments: [String] { ["/bin/sh", "-c", "exec /bin/zsh -l"] }
    public func commandArguments(_ command: String? = nil) -> [String] {
        if let command, !command.isEmpty {
            return ["/bin/sh", "-c", "exec /bin/zsh -lc \"$1\"", "cmux-ssh", command]
        }
        return ["/bin/sh", "-c", "exec /bin/zsh -l"]
    }
    public init(configuration: Any? = nil, _ args: Any...) {
        if let config = configuration as? WorkspaceRemoteConfiguration {
            self.id = config.destination
        }
    }
}

// MARK: 3. Cloud TUI Requests, Protocols & Commands
public protocol CloudTuiCommandRunning: AnyObject, Sendable {
    func runTuiCommand(arguments: CloudTuiRequest, deadline: Duration) async throws -> Data
}

public struct CloudTuiRequest: Sendable, Equatable {
    public let operation: String
    public let parameters: Data
    public let raw: Bool
    public var idempotencyKey: String?

    public init(_ operation: String, _ params: [String: Any] = [:], mutation: Bool = false, key: String? = nil, raw: Bool = false) {
        self.operation = operation
        self.raw = raw
        self.parameters = (try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys])) ?? Data()
        self.idempotencyKey = mutation ? (key ?? "mutation-\\(UUID().uuidString.lowercased())") : nil
    }

    public var params: [String: Any] { (try? JSONSerialization.jsonObject(with: parameters)) as? [String: Any] ?? [:] }
    public func adding(_ fields: [String: Any]) -> Self { self }
    public func withIdempotencyKey(_ key: String) -> Self { self }
}

public enum CloudTuiRequests {
    public static func snapshotArguments(socketPath: String = "") -> CloudTuiRequest { CloudTuiRequest("session.snapshot") }
    public static func createWorkspaceArguments(socketPath: String = "", name: String? = nil, empty: Bool = false) -> CloudTuiRequest {
        CloudTuiRequest("workspace.create", ["initial_content": empty ? "empty" : "terminal"], mutation: true)
    }
    public static func runArguments(socketPath: String = "", workspaceID: String = "", command: [String]? = nil, onExit: String? = nil, cwd: String? = nil, idempotencyKey: String? = nil, correlationKey: String? = nil) -> CloudTuiRequest {
        CloudTuiRequest("workspace.run", ["workspace": workspaceID, "argv": command], mutation: true, key: idempotencyKey)
    }
    public static func createBrowserArguments(socketPath: String = "", workspaceID: String? = nil, screenID: String? = nil, paneID: String? = nil, url: String = "", name: String? = nil, widthPx: Int? = nil, heightPx: Int? = nil, idempotencyKey: String? = nil, correlationKey: String? = nil) -> CloudTuiRequest {
        CloudTuiRequest("tab.create_browser", ["url": url], mutation: true, key: idempotencyKey)
    }
    public static func paneCreate(paneID: String = "", direction: String? = nil, command: [String]? = nil, revision: UInt64? = nil, key: String = "", correlationKey: String? = nil) -> CloudTuiRequest {
        CloudTuiRequest("pane.create", ["pane": paneID], mutation: true, key: key)
    }
    public static func closeTerminalArguments(socketPath: String = "", terminalID: String = "") -> CloudTuiRequest { CloudTuiRequest("terminal.close") }
    public static func closeTabArguments(socketPath: String = "", tabID: String = "") -> CloudTuiRequest { CloudTuiRequest("tab.close") }
    public static func closeWorkspaceArguments(socketPath: String = "", workspaceID: String = "", _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("workspace.close") }
    public static func renameWorkspaceArguments(socketPath: String = "", workspaceID: String = "", name: String = "", expectedRevision: Any? = nil) -> CloudTuiRequest { CloudTuiRequest("workspace.rename") }
    public static func renameTabArguments(socketPath: String = "", tabID: String = "", name: String = "", expectedRevision: Any? = nil) -> CloudTuiRequest {
        CloudTuiRequest("tab.rename", ["name": name], mutation: true)
    }
    public static func projectTerminalArguments(socketPath: String = "", terminalID: String = "", target: Any? = nil, expectedRevision: String? = nil, idempotencyKey: String? = nil) -> CloudTuiRequest { CloudTuiRequest("terminal.project") }
    public static func moveTabArguments(socketPath: String = "", tabID: String = "", target: Any? = nil, expectedRevision: Any? = nil, idempotencyKey: String? = nil, _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("tab.move") }
    public static func applyWorkspaceLayoutArguments(workspaceID: String = "", document: Any? = nil, expectedRevision: Any? = nil, _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("workspace.layout") }
    public static func listeningPortsArguments(socketPath: String = "") -> CloudTuiRequest? { CloudTuiRequest("machine-listening-tcp", raw: true) }
    public static func processInfoArguments(socketPath: String = "", terminalID: String = "") -> CloudTuiRequest { CloudTuiRequest("terminal.process.get", ["terminal": terminalID]) }
    public static func processWaitArguments(socketPath: String = "", terminalID: String = "") -> CloudTuiRequest { CloudTuiRequest("terminal.wait_exit", ["terminal": terminalID]) }
    public static func outputReadArguments(socketPath: String = "", terminalID: String = "", offset: UInt64? = nil, maxBytes: Int? = nil, _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("terminal.output_read", ["terminal": terminalID]) }
    public static func keysArguments(socketPath: String = "", terminalID: String = "", keys: String = "", _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("terminal.input.keys", ["terminal": terminalID, "keys": keys], mutation: true) }
    public static func screenReadArguments(socketPath: String = "", terminalID: String = "", _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("terminal.screen.read", ["terminal": terminalID]) }
    public static func screenWaitArguments(socketPath: String = "", terminalID: String = "", pattern: String = "", _ args: Any...) -> CloudTuiRequest { CloudTuiRequest("terminal.wait", ["terminal": terminalID, "pattern": pattern]) }
}

public struct CloudTuiCommandLine: Sendable {
    public static var defaultTerminalCommand: [String] { ["/bin/zsh", "-l"] }
    public static func attachShellCommand(clientPath: String, socketPath: String, terminalID: String) -> String {
        "exec \"\\(clientPath)\" attach --socket \"\\(socketPath)\" --terminal \"\\(terminalID)\""
    }
    public static func foregroundWorkingDirectory(fromProcessInfo: Any? = nil) -> String? { nil }
    public static func listeningPortsArguments(socketPath: String = "") -> [String]? { nil }
    public static func resolveTerminalArguments(_ args: Any...) -> [String] { [] }
    public static func identifyArguments(_ args: Any...) -> [String] { [] }
    public static func notificationAckArguments(_ args: Any...) -> [String] { [] }
    public static func renameWorkspaceArguments(_ args: Any...) -> [String] { [] }
    public static func renameTabArguments(_ args: Any...) -> [String] { [] }
    public static func snapshotArguments(_ args: Any...) -> [String] { [] }
    public static func eventsArguments(_ args: Any...) -> [String] { [] }
    public static func runArguments(_ args: Any...) -> [String] { [] }
    public static func attachArguments(_ args: Any...) -> [String] { [] }
}

public struct CloudTuiClientPaths: Sendable {
    public init() {}
    public static func candidateURLs() -> [URL] { [] }
    public static func resolveClientURL() -> URL? { nil }
    public static func stateDirectoryURL() -> URL { URL(fileURLWithPath: "/tmp") }
    public static func stateDirectory() -> String { "/tmp" }
    public static func defaultClientURL() -> URL? { nil }
    public static func deviceName() -> String { "wmux-mac" }
}

public enum CloudTuiManualMirrorPhase: Equatable, Sendable {
    case idle, connecting, attached, disconnected, stopped
}

public struct CloudTuiTerminalProjectionTarget: Sendable, Equatable {
    public var workspaceID: String
    public var screenID: String
    public var paneID: String
    public var index: Int
    public init(workspaceID: String = "", screenID: String = "", paneID: String = "", index: Int = 0) {
        self.workspaceID = workspaceID; self.screenID = screenID; self.paneID = paneID; self.index = index
    }
}

public enum CloudTuiSurfaceIDResolution: Equatable, Sendable {
    case resolved(UInt64)
    case noPlacement
    case exited
    case retryable(String, failure: Failure = .notReady)

    public enum Failure: Equatable, Sendable {
        case transportUnavailable, invalidResponse, rejected, notReady
        public var localizedDescription: String { "Failure" }
    }
}

extension WmuxTuiSnapshotParser {
    public static func terminalPlacement(from data: Data, terminalID: String) async -> (placement: SurfaceRemotePlacement?, revision: UInt64?)? {
        (placement: SurfaceRemotePlacement(workspaceID: "", tabID: ""), revision: 1)
    }
    public static func placedTab(from data: Data, at target: CloudTuiTerminalProjectionTarget, tabID: String? = nil, terminalID: String? = nil, _ args: Any...) async -> SurfaceRemotePlacement? {
        SurfaceRemotePlacement(workspaceID: target.workspaceID, tabID: tabID ?? "")
    }
    public static func terminalProjectionTarget(from data: Data, preferringWorkspace: String? = nil, _ args: Any...) async -> (target: CloudTuiTerminalProjectionTarget, revision: UInt64?)? {
        (target: CloudTuiTerminalProjectionTarget(workspaceID: preferringWorkspace ?? ""), revision: 1)
    }
    public static func mergingDisplays(pool: [SurfaceResource] = [], parsed: [SurfaceResource] = []) -> [SurfaceResource] {
        pool + parsed
    }
}

public final class CloudMachineLink: @unchecked Sendable, CloudTuiCommandRunning {
    public struct Connected: Sendable, Equatable {
        public var socketPath: String = ""
        public var session: String = ""
        public init(socketPath: String = "", session: String = "") {
            self.socketPath = socketPath; self.session = session
        }
    }

    public enum LinkError: Error, LocalizedError, Equatable {
        case exited(Int32 = 0, String = "")
        case timedOut
        case requestTimedOut
        case inputTooLarge
        case clientMissing
        case spawnFailed
        case failureMessage(String)
        public var errorDescription: String? { "Cloud link error" }
    }

    public enum Change: Sendable, Equatable {
        case connected(Connected)
        case snapshot(cursor: CloudVMCursor? = nil, delta: Bool = false, payload: Data = Data())
        case delta(cursor: CloudVMCursor = CloudVMCursor(), previousRevision: UInt64 = 0, revision: UInt64 = 0, payload: Data = Data())
        case streamEnded(reason: String = "", error: Error? = nil)
        case unknown
        public static func == (lhs: Change, rhs: Change) -> Bool { true }
    }

    public static let eventsRecoveryExhaustedReason = "events_recovery_exhausted"
    public static func errorText(_ error: Error) -> String { "\\(error)" }

    public var isConnected: Bool = false
    public var connected: Connected? = nil
    public var changes: AsyncStream<Change> { AsyncStream { $0.finish() } }

    public init(_ args: Any...) {}
    public func connect(_ args: Any...) async throws {}
    public func disconnect() async {}
    public func setEventsCursor(_ cursor: CloudVMCursor?) {}
    public func resumeEventsSubscription(from cursor: CloudVMCursor = CloudVMCursor(), _ args: Any...) async -> Bool { true }
    public func suspendEventsSubscription() async {}
    public func run(arguments: CloudTuiRequest, timeout: Duration = .seconds(30)) async throws -> Data { Data() }
    public func sendUntrackedTuiCommand(arguments: CloudTuiRequest) async throws {}
    public func runTuiCommand(arguments: CloudTuiRequest, deadline: Duration) async throws -> Data { Data() }
}

public final class CloudTerminalMutationCommandRunner: CloudTuiCommandRunning, @unchecked Sendable {
    public func sendUntrackedTuiCommand(arguments: CloudTuiRequest) async throws {}
    public init(base: any CloudTuiCommandRunning, validate: @escaping @MainActor @Sendable () throws -> Void = {}) {}
    public func runTuiCommand(arguments: CloudTuiRequest, deadline: Duration = .seconds(30)) async throws -> Data { Data() }
}

@MainActor
public final class CloudTerminalMutationQueue {
    public nonisolated init() {}
    public func enqueue<Value: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> Value) -> Task<Value, Error> {
        Task { try await operation() }
    }
}

public actor CloudMachineLinkManager: RemoteTuiLinkManaging {
    @TaskLocal public static var isBackgroundUpkeep = false

    public enum ManagerError: Error, LocalizedError {
        case clientMissing, wireGuardHubMissing, wireGuardHubUnsupported, privateRouteRequired
        case retryLater(String = "")
        public var errorDescription: String? { "Manager error" }
    }

    public struct LinkStatus: Sendable, Equatable {
        public let state: SurfaceLinkState
        public let error: String?
        public init(state: SurfaceLinkState = .ready, error: String? = nil) {
            self.state = state; self.error = error
        }
    }

    public init(
        paths: CloudTuiClientPaths = CloudTuiClientPaths(),
        clientURL: URL? = nil,
        hub: CloudWireGuardHub? = nil,
        operations: CloudOperationRecorder? = nil,
        isCloudEnabled: @escaping @Sendable () -> Bool = { true },
        resumeMachine: (@Sendable (String) async throws -> String)? = nil,
        hostThemeColors: (@Sendable () async -> (foreground: String, background: String)?)? = nil,
        breadcrumb: (@Sendable (_ event: String, _ fields: [String: String]) -> Void)? = nil,
        privateRouteConnector: Any? = nil,
        _ args: Any...
    ) {}
    public func markTrustedCarrier(machineID: String) {}
    public func setCreatedTrustedCarrierEndpoint(_ endpoint: VMCmuxRemoteEndpoint, for machineID: String) {}
    public func session(for machineID: String) -> String { "" }
    public func setPrivateAddresses(_ addresses: [String], for machineID: String) async {}
    public func setPrivateAddresses(_ addresses: [String] = [], for machineID: String = "", _ args: Any...) async {}
    public nonisolated func setPrivateAddresses(_ args: Any...) {}
    public func setOwnerTeam(_ teamID: String?, for machineID: String) {}
    public func ownerTeam(for machineID: String) -> String? { nil }
    public func privateAddresses(for machineID: String) -> [String] { [] }
    public func privateRoute(for machineID: String) -> String? { nil }
    public func resolvedPrivateRoute(machineID: String, through hub: CloudWireGuardHub.Ready, fallbackRoute: String, addresses: [String]) async throws -> String { fallbackRoute }
    public func connected(machineID: String) async throws -> CloudMachineLink.Connected { CloudMachineLink.Connected() }
    public func link(machineID: String) async -> CloudMachineLink? { nil }
    public func setMachineStatus(_ status: String, for machineID: String, observedAt: Date = Date()) -> Bool { true }
    public func recordLocalMachineStatus(_ status: String, for machineID: String) {}
    public nonisolated func browserProxy(machineID: String = "") async throws -> Any? { CloudBrowserProxyEndpoint() }
    public nonisolated func browserProxy(_ args: Any...) async throws -> Any? { CloudBrowserProxyEndpoint() }
    public func browserProxy(machineID: String, remoteNetwork: Bool = false) async throws -> CloudBrowserProxyEndpoint { CloudBrowserProxyEndpoint() }
    public var connectedMachineCount: Int { 0 }
    public nonisolated func status(machineID: String) async -> CloudTuiLinkStatus? { nil }
    public func disconnect(machineID: String) async {}
    public func disconnectAll() async {}
    public func retainAddresses(machineIDs: Set<String> = []) {}
    public func pushHostThemeToConnectedLinks() async {}
}

// MARK: 4. Cloud VM Client, Summaries & Policies

public struct VMCapabilities: Sendable, Codable, Equatable {
    public var snapshot: Bool
    public var restore: Bool
    public var fork: Bool
    public var exec: Bool
    public var stats: Bool
    public var restart: Bool
    public var ports: Bool
    public var desktop: Bool
    public var sizing: Bool
    public var persistentHome: Bool
    public var attachTransports: [String]?

    public static let legacy = VMCapabilities()
    public static let all = VMCapabilities(snapshot: true, restore: true, fork: true, exec: true, stats: true, restart: true, ports: true, desktop: true, sizing: true, persistentHome: true, attachTransports: nil)

    public init(
        snapshot: Bool = false, restore: Bool = false, fork: Bool = false,
        exec: Bool = true, stats: Bool = true, restart: Bool = false, ports: Bool = true,
        desktop: Bool = true, sizing: Bool = true, persistentHome: Bool = true,
        attachTransports: [String]? = ["ssh"]
    ) {
        self.snapshot = snapshot
        self.restore = restore
        self.fork = fork
        self.exec = exec
        self.stats = stats
        self.restart = restart
        self.ports = ports
        self.desktop = desktop
        self.sizing = sizing
        self.persistentHome = persistentHome
        self.attachTransports = attachTransports
    }
}

public typealias VMMachineKind = WmuxSurfaceCatalogModel.VMMachineKind

public struct VMBaseSummary: Equatable, Sendable { public init(_ args: Any...) {} }
public struct VMCreator: Equatable, Sendable { public init(_ args: Any...) {} }
public struct CloudAgentUpdates: Equatable, Sendable { public init(_ args: Any...) {} }
public struct CloudVMResourceReservation: Equatable, Sendable { public init(_ args: Any...) {} }

public struct VMSummary: Equatable, Sendable {
    public var id: String
    public var provider: String
    public var status: String
    public var image: String
    public var createdAt: Int64
    public var base: VMBaseSummary? = nil
    public var kind: VMMachineKind? = nil
    public var capabilities: VMCapabilities
    public var displayName: String? = nil
    public var slug: String? = nil
    public var freeAccessExpiresAt: Int64? = nil
    public var addressIPv4: String? = nil
    public var addressIPv6: String? = nil
    public var cmuxTuiContract: String? = nil
    public var createdBy: VMCreator? = nil
    public var agentUpdates: CloudAgentUpdates? = nil
    public var createAttach: VMCmuxRemoteEndpoint? = nil
    public var resourceReservation: CloudVMResourceReservation? = nil
    public var resourcePoolClaim: CloudVMResourceReservation? = nil

    public var preferredPrivateAddress: String? { addressIPv4 }
    public var preferredName: String { displayName ?? id }
    public var resolvedKind: VMMachineKind { kind ?? .desktop }
    public func withStatus(_ newStatus: String) -> VMSummary { var c = self; c.status = newStatus; return c }

    public init(
        id: String = "",
        provider: String = "",
        status: String = "",
        image: String = "",
        createdAt: Int64 = 0,
        base: VMBaseSummary? = nil,
        kind: VMMachineKind? = nil,
        capabilities: VMCapabilities = .all,
        displayName: String? = nil,
        slug: String? = nil,
        freeAccessExpiresAt: Int64? = nil,
        addressIPv4: String? = nil,
        addressIPv6: String? = nil,
        cmuxTuiContract: String? = nil,
        createdBy: VMCreator? = nil,
        agentUpdates: CloudAgentUpdates? = nil,
        createAttach: VMCmuxRemoteEndpoint? = nil,
        resourceReservation: CloudVMResourceReservation? = nil,
        resourcePoolClaim: CloudVMResourceReservation? = nil,
        _ args: Any...
    ) {
        self.id = id; self.provider = provider; self.status = status; self.image = image
        self.createdAt = createdAt; self.base = base; self.kind = kind
        self.capabilities = capabilities; self.displayName = displayName; self.slug = slug
        self.freeAccessExpiresAt = freeAccessExpiresAt; self.addressIPv4 = addressIPv4
        self.addressIPv6 = addressIPv6; self.cmuxTuiContract = cmuxTuiContract
        self.createdBy = createdBy; self.agentUpdates = agentUpdates; self.createAttach = createAttach
        self.resourceReservation = resourceReservation; self.resourcePoolClaim = resourcePoolClaim
    }

    public static func == (lhs: VMSummary, rhs: VMSummary) -> Bool { lhs.id == rhs.id }
}

public struct VMCmuxRemoteEndpoint: Equatable, Sendable {
    public let route: String
    public let token: String
    public let expiresAtUnix: Int64
    public let session: String
    public let trustedCarrier: Bool

    public struct NetworkAddresses: Equatable, Sendable {
        public let ipv4: String?
        public let ipv6: String?
        public init(ipv4: String? = nil, ipv6: String? = nil, _ args: Any...) {
            self.ipv4 = ipv4; self.ipv6 = ipv6
        }
    }
    public let networkAddresses: NetworkAddresses?

    public init(
        route: String = "",
        token: String = "",
        expiresAtUnix: Int64 = 0,
        session: String = "",
        trustedCarrier: Bool = false,
        networkAddresses: NetworkAddresses? = nil,
        _ args: Any...
    ) {
        self.route = route; self.token = token; self.expiresAtUnix = expiresAtUnix
        self.session = session; self.trustedCarrier = trustedCarrier; self.networkAddresses = networkAddresses
    }
}

public struct VMListPage: Sendable {
    public var vms: [VMSummary]
    public var limits: VMPlanLimits?
    public var activeMachineCount: Int { limits?.activeVmCount ?? vms.count }
    public init(vms: [VMSummary] = [], limits: VMPlanLimits? = nil, _ args: Any...) {
        self.vms = vms; self.limits = limits
    }
}

public enum VMClientError: Error, LocalizedError, Equatable {
    case notSignedIn
    case sessionRefreshFailed
    case backendUnreachable
    case malformedResponse(String)
    case disabledByManagedPolicy
    case cloudMachinesDisabled
    case lifecycleUnsupported
    case httpStatus(Int, String)

    public var errorDescription: String? {
        switch self {
        case .httpStatus(let status, let body): return "HTTP \\(status): \\(body)"
        case .malformedResponse(let msg): return msg
        default: return "VMClientError"
        }
    }
}

public func formattedCloudVMHTTPError(status: Int, body: String) -> String {
    "Cloud VM request failed (HTTP \\(status))."
}

public struct VMPlanLimits: Sendable {
    public let maxActiveVms: Int?
    public let planId: String
    public let freeAccessWindowDays: Int
    public let freeAccessExpiresAt: Int64?
    public let memoryOptionsMb: [Int]
    public let maxDiskMb: Int?
    public let maxMemoryMb: Int?
    public let maxVcpus: Int?
    public let lockedMemoryOptionsMb: [Int]?
    public let memoryUpgradePlanId: String?
    public let memoryUpgradePlansByMb: [String: String]?
    public let vcpusByMemoryMb: [String: Int]?
    public let activeVmCount: Int?
    public let imageKinds: [Any]
    public let resourcePool: Any?

    public init(
        maxActiveVms: Int? = nil,
        planId: String = "free",
        freeAccessWindowDays: Int = 0,
        freeAccessExpiresAt: Int64? = nil,
        memoryOptionsMb: [Int] = [],
        maxDiskMb: Int? = nil,
        maxMemoryMb: Int? = nil,
        maxVcpus: Int? = nil,
        lockedMemoryOptionsMb: [Int]? = nil,
        memoryUpgradePlanId: String? = nil,
        memoryUpgradePlansByMb: [String: String]? = nil,
        vcpusByMemoryMb: [String: Int]? = nil,
        activeVmCount: Int? = nil,
        imageKinds: [Any] = [],
        resourcePool: Any? = nil,
        _ args: Any...
    ) {
        self.maxActiveVms = maxActiveVms
        self.planId = planId
        self.freeAccessWindowDays = freeAccessWindowDays
        self.freeAccessExpiresAt = freeAccessExpiresAt
        self.memoryOptionsMb = memoryOptionsMb
        self.maxDiskMb = maxDiskMb
        self.maxMemoryMb = maxMemoryMb
        self.maxVcpus = maxVcpus
        self.lockedMemoryOptionsMb = lockedMemoryOptionsMb
        self.memoryUpgradePlanId = memoryUpgradePlanId
        self.memoryUpgradePlansByMb = memoryUpgradePlansByMb
        self.vcpusByMemoryMb = vcpusByMemoryMb
        self.activeVmCount = activeVmCount
        self.imageKinds = imageKinds
        self.resourcePool = resourcePool
    }

    public static func isPaidPlanID(_ planId: String) -> Bool { planId != "free" }
}

public struct VMStats: Sendable, Codable, Equatable {
    public var memoryTotalMb: Int = 0
    public var memoryUsedMb: Int = 0
    public var cpuPercent: Double = 0.0
    public var diskTotalMb: Int = 0
    public var diskUsedMb: Int = 0
    public var cpus: Int = 0
    public init(memoryTotalMb: Int = 0, memoryUsedMb: Int = 0, cpuPercent: Double = 0.0, diskTotalMb: Int = 0, diskUsedMb: Int = 0, cpus: Int = 0, _ args: Any...) {
        self.memoryTotalMb = memoryTotalMb; self.memoryUsedMb = memoryUsedMb
        self.cpuPercent = cpuPercent; self.diskTotalMb = diskTotalMb
        self.diskUsedMb = diskUsedMb; self.cpus = cpus
    }
}

public struct VMExecResult: Sendable, Codable, Equatable {
    public var exitCode: Int32 = 0
    public var stdout: String = ""
    public var stderr: String = ""
    public init(exitCode: Int32 = 0, stdout: String = "", stderr: String = "", _ args: Any...) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

public final class VMClient: @unchecked Sendable {
    public static var shared: VMClient! = VMClient()
    public init(_ args: Any...) {}
    public func exec(id: String, command: String, timeoutMs: Int = 10000, teamID: String? = nil, _ args: Any...) async throws -> VMExecResult {
        VMExecResult()
    }
    public func status(id: String, teamID: String? = nil, _ args: Any...) async throws -> VMSummary {
        VMSummary(id: id)
    }
    public func stats(id: String, teamID: String? = nil, _ args: Any...) async throws -> VMStats {
        VMStats()
    }
    public func listPage(allowWhenCloudDisabled: Bool = false, expectedTeamScope: Any? = nil, _ args: Any...) async throws -> VMListPage {
        VMListPage()
    }
    public func listPage(_ args: Any...) async throws -> VMListPage { VMListPage() }
}

public protocol NewMachineSheetPresenting: AnyObject, Sendable {}

public enum MachineSnapshotBuilder {
    public static func planSnapshot(
        activeCount: Int,
        limits: VMPlanLimits?,
        _ args: Any...
    ) -> MachinePlanSnapshot? {
        guard let limits else { return nil }
        return MachinePlanSnapshot(
            activeCount: activeCount,
            maxActiveVms: limits.maxActiveVms,
            planId: limits.planId,
            freeAccessWindowDays: limits.freeAccessWindowDays,
            freeAccessExpiresAt: limits.freeAccessExpiresAt
        )
    }
    public static func planSnapshot(_ args: Any...) -> Any? { nil }
}

public enum ManagedCloudPolicy: Sendable {
    public static var isDisabled: Bool { false }
    public static var isEnabled: Bool { true }
    public static let socketErrorCode = "cloud_disabled"
    public static var disabledMessage: String { "Cloud Machines are disabled." }
}

public enum ManagedRemoteConnectionsPolicy: Sendable {
    public static var isDisabled: Bool { false }
    public static var isEnabled: Bool { true }
    public static let socketErrorCode = "remote_connections_disabled"
    public static var disabledMessage: String { "Remote connections are disabled." }
}

public enum ManagedIrohNetworkingPolicy: Sendable {
    public static var isDisabled: Bool { false }
    public static var isEnabled: Bool { true }
    public static let socketErrorCode = "iroh_networking_disabled"
    public static var disabledMessage: String { "Relay networking is disabled." }
}

public enum CloudVMPanelAuthState: Equatable, Sendable {
    case checking, signedOut, signedIn
    public static func resolve(isAuthenticated: Bool = false, isWorkingOnAuth: Bool = false) -> Self { .signedIn }
}

public enum CloudMachineAccessLoss: Equatable, Sendable {
    case notFound, forbidden, ownerMismatch, subscriptionEnded, unknown, unauthenticated, signInRevoked
    public static func classify(_ error: Error) -> CloudMachineAccessLoss? { nil }
}

// MARK: 5. Current Work, Surfaces & Placement
public struct CurrentWorkSnapshot: Codable, Sendable {
    public struct Receipt: Codable, Sendable {
        public var kind: String
        public var cursor: String
        public var evidence: Evidence
        public init(kind: String = "", cursor: String = "", evidence: Evidence = Evidence()) {
            self.kind = kind; self.cursor = cursor; self.evidence = evidence
        }
        public init(kind: String = "", cursor: CloudVMCursor?, evidence: Evidence = Evidence(), _ args: Any...) {
            self.kind = kind; self.cursor = cursor.map(String.init(describing:)) ?? ""; self.evidence = evidence
        }
    }

    public init(observedAt: String = "", totalObserved: Int = 0, truncated: Bool = false, ownerAvailability: [String: String] = [:], items: [Item] = [], _ args: Any...) {
        self.observedAt = observedAt
        self.totalObserved = totalObserved
        self.truncated = truncated
        self.ownerAvailability = ownerAvailability
        self.items = items
    }

    public var authority = "read_only_projection"
    public var observedAt: String = ""
    public var totalObserved: Int = 0
    public var truncated: Bool = false
    public var ownerAvailability: [String: String] = [:]
    public var items: [Item] = []

    public struct Evidence: Codable, Sendable {
        public var owner: String = ""
        public var reference: String = ""
        public var observedAt: String = ""
        public init(owner: String = "", reference: String = "", observedAt: String = "") {
            self.owner = owner; self.reference = reference; self.observedAt = observedAt
        }
    }

    public struct Freshness: Codable, Sendable {
        public var state: String = ""
        public var reason: String?
        public var observedAt: String = ""
        public init(state: String = "", reason: String? = nil, observedAt: String = "") {
            self.state = state; self.reason = reason; self.observedAt = observedAt
        }
    }

    public struct Placement: Codable, Sendable {
        public var kind: String = ""
        public var machine: String = ""
        public init(kind: String = "", machine: String = "") { self.kind = kind; self.machine = machine }
    }

    public struct Projection: Codable, Sendable {
        public var panelID: UUID = UUID()
        public var workspaceID: UUID = UUID()
        public var screenID: UUID?
        public var index: Int = 0
        public var resourceRef: String = ""
        public var stableSurfaceID: UUID? = nil
        public var stableWorkspaceID: UUID? = nil
        public var panePlacementID: UUID? = nil
        public var remoteWorkspaceID: String? = nil
        public var remoteTabID: String? = nil
        public init(
            resourceRef: String = "",
            workspaceID: UUID = UUID(),
            panelID: UUID = UUID(),
            screenID: UUID? = nil,
            index: Int = 0,
            stableSurfaceID: UUID? = nil,
            stableWorkspaceID: UUID? = nil,
            panePlacementID: UUID? = nil,
            remoteWorkspaceID: String? = nil,
            remoteTabID: String? = nil,
            _ args: Any...
        ) {
            self.panelID = panelID; self.workspaceID = workspaceID; self.screenID = screenID; self.index = index
            self.resourceRef = resourceRef; self.stableSurfaceID = stableSurfaceID; self.stableWorkspaceID = stableWorkspaceID; self.panePlacementID = panePlacementID
            self.remoteWorkspaceID = remoteWorkspaceID; self.remoteTabID = remoteTabID
        }
    }

    public struct Agent: Codable, Sendable {
        public var kind: String? = nil
        public var sessionID: String? = nil
        public var hasHookLifecycleState: Bool = false
        public var label: String = ""
        public var state: String = ""
        public var detail: String?
        public var freshness: Freshness = Freshness()
        public var evidence: Evidence = Evidence()
        public init(sessionID: String? = nil, kind: String? = nil, label: String = "", state: String = "", detail: String? = nil, hasHookLifecycleState: Bool = false, version: Int? = nil, lastActivityAt: String? = nil, freshness: Freshness = Freshness(), evidence: Evidence = Evidence(), _ args: Any...) {
            self.sessionID = sessionID
            self.kind = kind
            self.label = label.isEmpty ? (sessionID ?? "") : label
            self.state = state
            self.detail = detail ?? lastActivityAt
            self.hasHookLifecycleState = hasHookLifecycleState
            self.freshness = freshness
            self.evidence = evidence
        }
        public init(kind: String = "", label: String = "", state: String = "", detail: String? = nil, freshness: Freshness = Freshness(), evidence: Evidence = Evidence()) {
            self.init(sessionID: label, kind: kind, label: label, state: state, detail: detail, hasHookLifecycleState: false, version: nil, lastActivityAt: nil, freshness: freshness, evidence: evidence)
        }
    }

    public struct Attention: Codable, Sendable {
        public var kind: String = ""
        public var scope: String = ""
        public var evidence: Evidence = Evidence()
        public init(kind: String = "", scope: String = "", evidence: Evidence = Evidence()) {
            self.kind = kind; self.scope = scope; self.evidence = evidence
        }
    }

    public struct PullRequest: Codable, Sendable {
        public var number: Int = 0
        public var url: String = ""
        public var label: String = ""
        public var status: String = ""
        public var workspaceID: UUID = UUID()
        public var freshness: Freshness = Freshness()
        public var evidence: Evidence = Evidence()
        public init(number: Int = 0, url: String = "", label: String = "", status: String = "", workspaceID: UUID = UUID(), freshness: Freshness = Freshness(), evidence: Evidence = Evidence()) {
            self.number = number; self.url = url; self.label = label; self.status = status; self.workspaceID = workspaceID; self.freshness = freshness; self.evidence = evidence
        }
    }

    public struct Obligation: Codable, Sendable {
        public var kind: String = ""
        public var label: String = ""
        public var scope: String = ""
        public var freshness: Freshness = Freshness()
        public var evidence: Evidence = Evidence()
        public init(kind: String = "", label: String = "", scope: String = "", freshness: Freshness = Freshness(), evidence: Evidence = Evidence(), _ args: Any...) {
            self.kind = kind; self.label = label; self.scope = scope; self.freshness = freshness; self.evidence = evidence
        }
    }

    public struct Item: Codable, Sendable {
        public var resourceRef: String = ""
        public var durableSurfaceID: UUID?
        public var label: String = ""
        public var kind: String = ""
        public var lifecycle: String = ""
        public var placement: Placement = Placement()
        public var projections: [Projection] = []
        public var cwd: String?
        public var projectHints: [String] = []
        public var repositoryHints: [String] = []
        public var agents: [Agent] = []
        public var attention: [Attention] = []
        public var pullRequests: [PullRequest] = []
        public var freshness: Freshness = Freshness()
        public var cursor: CloudVMCursor?
        public var receiptRefs: [Receipt] = []
        public var possibleHumanObligations: [Obligation] = []
        public var evidence: [Evidence] = []
        public var omitted: [String: Int] = [:]

        public init(
            resourceRef: String = "",
            durableSurfaceID: UUID? = nil,
            label: String = "",
            kind: String = "",
            lifecycle: String = "",
            placement: Placement = Placement(),
            projections: [Projection] = [],
            cwd: String? = nil,
            projectHints: [String] = [],
            repositoryHints: [String] = [],
            agents: [Agent] = [],
            attention: [Attention] = [],
            pullRequests: [PullRequest] = [],
            freshness: Freshness = Freshness(),
            cursor: CloudVMCursor? = nil,
            receiptRefs: [Receipt] = [],
            possibleHumanObligations: [Obligation] = [],
            evidence: [Evidence] = [],
            omitted: [String: Int] = [:],
            _ args: Any...
        ) {
            self.resourceRef = resourceRef; self.durableSurfaceID = durableSurfaceID; self.label = label; self.kind = kind
            self.lifecycle = lifecycle; self.placement = placement; self.projections = projections; self.cwd = cwd
            self.projectHints = projectHints; self.repositoryHints = repositoryHints; self.agents = agents
            self.attention = attention; self.pullRequests = pullRequests; self.freshness = freshness
            self.cursor = cursor; self.receiptRefs = receiptRefs; self.possibleHumanObligations = possibleHumanObligations
            self.evidence = evidence; self.omitted = omitted
        }
    }
}

public struct CurrentWorkObservation: Sendable {
    public var export: SurfaceCatalogExport = SurfaceCatalogExport(catalog: SurfaceCatalogSnapshot.empty, cloudStates: [])
    public var observedAt: Date = Date()
    public var workspaces: [UUID: WorkspaceFacts] = [:]
    public var agentsByPanelID: [UUID: [CurrentWorkSnapshot.Agent]] = [:]
    public var unreadPanelIDs: Set<UUID> = []
    public var agentOwnerAvailable: Bool = false

    public struct WorkspaceFacts: Sendable {
        public var projectRoot: String?
        public var unreadCount: Int
        public var notificationID: UUID?
        public var pullRequests: [CurrentWorkSnapshot.PullRequest]
        public init(projectRoot: String? = nil, unreadCount: Int = 0, notificationID: UUID? = nil, pullRequests: [CurrentWorkSnapshot.PullRequest] = []) {
            self.projectRoot = projectRoot; self.unreadCount = unreadCount; self.notificationID = notificationID; self.pullRequests = pullRequests
        }
    }

    public init(export: SurfaceCatalogExport = SurfaceCatalogExport(catalog: SurfaceCatalogSnapshot.empty, cloudStates: []), observedAt: Date = Date(), workspaces: [UUID: WorkspaceFacts] = [:], agentsByPanelID: [UUID: [CurrentWorkSnapshot.Agent]] = [:], unreadPanelIDs: Set<UUID> = [], agentOwnerAvailable: Bool = false, _ args: Any...) {
        self.export = export; self.observedAt = observedAt; self.workspaces = workspaces
        self.agentsByPanelID = agentsByPanelID; self.unreadPanelIDs = unreadPanelIDs; self.agentOwnerAvailable = agentOwnerAvailable
    }
}

public struct CurrentWorkInput: Sendable {
    public var export: SurfaceCatalogExport
    public var observedAt: Date
    public var workspaces: [UUID: CurrentWorkObservation.WorkspaceFacts]
    public var agentsByPanelID: [UUID: [CurrentWorkSnapshot.Agent]]
    public var unreadPanelIDs: Set<UUID>
    public var agentOwnerAvailable: Bool
    public init(export: SurfaceCatalogExport = SurfaceCatalogExport(catalog: SurfaceCatalogSnapshot.empty, cloudStates: []), observedAt: Date = Date(), workspaces: [UUID: CurrentWorkObservation.WorkspaceFacts] = [:], agentsByPanelID: [UUID: [CurrentWorkSnapshot.Agent]] = [:], unreadPanelIDs: Set<UUID> = [], agentOwnerAvailable: Bool = false, _ args: Any...) {
        self.export = export; self.observedAt = observedAt; self.workspaces = workspaces
        self.agentsByPanelID = agentsByPanelID; self.unreadPanelIDs = unreadPanelIDs; self.agentOwnerAvailable = agentOwnerAvailable
    }
}

public struct SurfaceRemotePlacement: Equatable, Sendable {
    public var workspaceID: String
    public var tabID: String
    public var cursor: CloudVMCursor? = nil
    public init(workspaceID: String = "", tabID: String = "", cursor: CloudVMCursor? = nil, _ args: Any...) {
        self.workspaceID = workspaceID; self.tabID = tabID; self.cursor = cursor
    }
}

@MainActor
public protocol SurfacePlacementSyncing: AnyObject {
    func moveRemoteTab(id: String, intoRemoteWorkspace remoteWorkspaceID: String) async throws -> SurfaceRemotePlacement
    func projectTerminal(_ id: SurfaceResourceID, intoRemoteWorkspace remoteWorkspaceID: String) async throws -> SurfaceRemotePlacement
    func closeRemoteTab(id: String, inRemoteWorkspace remoteWorkspaceID: String) async throws
}

public struct SurfaceOwnershipPolicy: Equatable, Sendable {
    public let cloudMachine: SurfaceMachineID?
    public init(cloudMachine: SurfaceMachineID? = nil, _ args: Any...) {
        self.cloudMachine = cloudMachine
    }
    public func rejection(for source: SurfaceMachineID?, kind: SurfaceResourceKind? = nil) -> SurfaceTransferRejection? { nil }
}

public enum SurfaceTransferOrigin: Equatable, Sendable {
    case workspace(UUID)
    case dock(UUID)
}

public enum SurfaceTransferRejection: Error, LocalizedError, Equatable, Sendable {
    case cloudMachineMismatch
    public var errorDescription: String? { message }
    public var message: String { "Cloud workspaces can only hold resources from their own machine." }
}

public enum SurfaceProjectionEndReason: Sendable, Equatable {
    case paneClosed
    case workspaceTeardown
    case remoteEnded
    case replaced
}

public struct CloudWorkspaceCreationReceipt: Sendable {
    public var workspace: SurfaceRemoteWorkspace = SurfaceRemoteWorkspace(id: "", name: "", index: 0, focused: false)
    public var tabID: String = ""
    public var cursor: CloudVMCursor? = nil
    public init(workspace: SurfaceRemoteWorkspace = SurfaceRemoteWorkspace(id: "", name: "", index: 0, focused: false), tabID: String = "", cursor: CloudVMCursor? = nil, _ args: Any...) {
        self.workspace = workspace; self.tabID = tabID; self.cursor = cursor
    }
    public init(workspaceID: String = "", tabID: String = "", cursor: CloudVMCursor? = nil, _ args: Any...) {
        self.workspace = SurfaceRemoteWorkspace(id: workspaceID, name: "", index: 0, focused: false)
        self.tabID = tabID; self.cursor = cursor
    }
}

public struct CloudWorkspaceCreationReservation: Sendable {
    public var id: UUID
    public var workspaceID: UUID = UUID()
    public var commandOverride: [String]?
    public var attemptKey: String
    public init(id: UUID = UUID(), commandOverride: [String]? = nil, attemptKey: String? = nil) {
        self.id = id; self.commandOverride = commandOverride; self.attemptKey = attemptKey ?? "cmux-cloud-create-\\(id.uuidString)"
    }
}

public final class CloudWorkspaceCreationCoordinator: @unchecked Sendable {
    public struct Operation: Sendable {
        public var machine: SurfaceMachineID = .local
        public var receipt: CloudWorkspaceCreationReceipt? = nil
        public var reservation: CloudWorkspaceCreationReservation? = nil
        public init(machine: SurfaceMachineID = .local, receipt: CloudWorkspaceCreationReceipt? = nil, reservation: CloudWorkspaceCreationReservation? = nil) {
            self.machine = machine; self.receipt = receipt; self.reservation = reservation
        }
    }
    public var operations: [UUID: Operation] = [:]
    public init(catalog: Any? = nil, _ args: Any...) {}
    public func create(_ args: Any...) {}
    public func cancel(machine: SurfaceMachineID? = nil, workspaceID: String? = nil, _ args: Any...) {}
    public func cancelAll() {}
    public func reconcile(_ args: Any...) {}
    public func projectionDidEnd(panelID: UUID? = nil, reason: Any? = nil, _ args: Any...) {}
    public func projectionDidEnd(_ args: Any...) {}
    public func activeWorkspaceCreationTarget(machine: SurfaceMachineID = .local) -> (workspaceID: String, panelID: UUID)? { nil }
    public func activeWorkspaceCreationReservation(machine: SurfaceMachineID = .local) -> CloudWorkspaceCreationReservation? { nil }
}

public enum CloudTerminalAttachmentMode: Sendable, Equatable {
    case attached, detached
    public var machineID: String { "" }
    public init(machineID: String = "", _ args: Any...) { self = .attached }
}

public final class CloudTerminalAttachmentRetryScheduler: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func cancel() {}
}

public final class CloudTerminalAttachmentLog: @unchecked Sendable { public init(_ args: Any...) {} }

@MainActor
@Observable
public final class CloudTerminalAttachmentStatus {
    public let machineID: String
    public init(machineID: String = "") { self.machineID = machineID }
}

public final class CloudTerminalCreationRequest: @unchecked Sendable {
    public let id: UUID
    public let commandOverride: [String]?
    public var remoteWorkspaceID: String?
    public let correlationKey: String
    public var attemptKey: String

    public init(id: UUID = UUID(), remoteWorkspaceID: String? = nil, commandOverride: [String]? = nil, restoring: Bool = false, _ args: Any...) {
        self.id = id
        self.remoteWorkspaceID = remoteWorkspaceID
        self.commandOverride = commandOverride
        self.correlationKey = UUID().uuidString
        self.attemptKey = "cmux-cloud-create-\\(id.uuidString)"
    }
}

public struct CloudTerminalSourcePlacement: Sendable {
    public let machine: SurfaceMachineID
    public let resource: SurfaceResource?
    public let remoteWorkspaceID: String?
    public let remoteTabID: String?
    public let pendingCreation: CloudWorkspaceCreationReceipt?
    public init(machine: SurfaceMachineID = .local, resource: SurfaceResource? = nil, remoteWorkspaceID: String? = nil, remoteTabID: String? = nil, pendingCreation: CloudWorkspaceCreationReceipt? = nil, _ args: Any...) {
        self.machine = machine; self.resource = resource; self.remoteWorkspaceID = remoteWorkspaceID; self.remoteTabID = remoteTabID; self.pendingCreation = pendingCreation
    }
}

public struct CloudAgentNameContext: Hashable, Codable, Sendable {
    public let projection: SurfaceProjection
    public let generation: String
    let nameRevision: UInt64
    public init?(projection: SurfaceProjection, state: CloudVMState) {
        self.projection = projection; self.generation = "gen"; self.nameRevision = 0
    }
    public init?(wire: Any?) {
        guard let dict = wire as? [String: Any],
              let pID = dict["panelID"] as? String, let pUUID = UUID(uuidString: pID) else {
            return nil
        }
        self.projection = SurfaceProjection(resource: SurfaceResourceID(machine: .local, kind: .terminal, key: "t"), workspaceID: UUID(), panelID: pUUID)
        self.generation = dict["generation"] as? String ?? "gen"
        self.nameRevision = 0
    }
    public var wire: [String: Any]? {
        ["panelID": projection.panelID.uuidString, "generation": generation]
    }
    public func renameRequest(name: String) -> CloudTuiRequest {
        CloudTuiRequest("tab.rename", ["name": name], mutation: true)
    }
}

public enum CloudTerminalPaneClosure {
    public static func panelsToClose(
        boundTerminals: [UUID: String],
        liveTerminalKeys: Set<String>,
        freshness: CloudVMStateFreshness,
        graphComplete: Bool = true
    ) -> [UUID] {
        guard freshness == .current, graphComplete else { return [] }
        return boundTerminals
            .filter { !liveTerminalKeys.contains($0.value) }
            .keys
            .sorted { $0.uuidString < $1.uuidString }
    }
}

public final class CloudProviderRefreshCoordinator: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func invalidate() {}
    public func cancel() {}
    public func refresh(force: Bool = false, _ args: Any...) async -> Bool { true }
}

@MainActor
public final class CloudReadRecoveryObserver {
    public init(notificationCenter: NotificationCenter = .default, recover: @escaping @MainActor @Sendable () async -> Void) {}
}

public final class CloudRenameCoordinator: @unchecked Sendable {
    public init(_ args: Any...) {}
    public struct Key: Hashable, Sendable {
        public enum Scope: String, Hashable, Sendable { case workspace, tab, terminal }
        public let machine: SurfaceMachineID
        public let scope: Scope
        public let remoteID: String
        public init(machine: SurfaceMachineID = .local, scope: Scope = .workspace, remoteID: String = "") {
            self.machine = machine; self.scope = scope; self.remoteID = remoteID
        }
        public static func workspace(machine: SurfaceMachineID = .local, id: String = "") -> Key {
            Key(machine: machine, scope: .workspace, remoteID: id)
        }
        public static func tab(machine: SurfaceMachineID = .local, id: String = "") -> Key {
            Key(machine: machine, scope: .tab, remoteID: id)
        }
        public static func terminal(machine: SurfaceMachineID = .local, id: String = "") -> Key {
            Key(machine: machine, scope: .terminal, remoteID: id)
        }
    }

    public var onPendingNamesChanged: @MainActor (SurfaceMachineID) -> Void = { _ in }
    public var allPendingNames: [Key: String] = [:]
    public func waitForPendingRenames(on machine: SurfaceMachineID) async throws {}

    @discardableResult
    public func enqueue(
        key: Key,
        pendingName: String,
        onFailure: @escaping @MainActor (Error) -> Void = { _ in },
        operation: @escaping () async throws -> Void
    ) -> Task<Void, Error> {
        Task {
            do {
                try await operation()
            } catch {
                await MainActor.run { onFailure(error) }
                throw error
            }
        }
    }

    public func pendingName(for key: Key) -> String? { nil }
    public func pendingName(_ args: Any...) -> String? { nil }
}

public struct CloudRequestBudget: Sendable {
    public init(_ args: Any...) {}
    public func withBudget<Result>(seconds: TimeInterval? = nil, isolation: isolated (any Actor)? = #isolation, _ operation: () async throws -> Result) async rethrows -> Result {
        try await operation()
    }
}

public struct CloudPortRoutePolicy: Sendable {
    public init(_ args: Any...) {}
    public func privateURL(_ raw: String, address: String, allowLoopback: Bool = false) -> URL? { URL(string: raw) }
    public func localURL(rewriting remoteURL: String, toLoopbackPort localPort: UInt16) -> URL? { URL(string: remoteURL) }
}

public protocol CloudHubDialing: Sendable {}

public struct CloudWireGuardHubDialer: CloudHubDialing, Sendable {
    public init(hub: CloudWireGuardHub = CloudWireGuardHub(), _ args: Any...) {}
}

public actor CloudWireGuardHub {
    public struct Ready: Sendable, Equatable {
        public var socketPath: String = ""
        public init(socketPath: String = "") { self.socketPath = socketPath }
    }
    public static func production(clientURL: URL? = nil, _ args: Any...) -> CloudWireGuardHub { CloudWireGuardHub() }
    public init(_ args: Any...) {}
    public func prepareForCloudUse(_ args: Any...) async {}
    public func cancelPreparation() async {}
    public func terminateForAppQuit() async {}
}

public struct CloudActivationPolicy: Sendable {
    public static var production: CloudActivationPolicy { CloudActivationPolicy() }
    public init(_ args: Any...) {}
    public func allowsFleetPolling() -> Bool { false }
    public func allowsWireGuardHubPreparation() -> Bool { false }
}

public actor CloudTunnelCoordinator {
    public init(_ args: Any...) {}
    public func start() {}
    public func stop() {}
}

@MainActor
public final class CloudOperationRecorder {
    public init(_ args: Any...) {}
    public func reset() {}
}

public struct CloudBrowserRouting: Sendable {
    public static func rewriteURLIfNeeded(_ url: URL, _ args: Any...) -> URL { url }
    public static func isCloudBrowserURL(_ url: URL) -> Bool { false }
}

public struct CloudBrowserProxyEndpoint: Sendable, Equatable, Decodable, CustomStringConvertible, CustomDebugStringConvertible {
    public let host: String
    public let port: UInt16
    public let username: String
    public let password: String
    public var websocketToken: String?

    public init(host: String = "127.0.0.1", port: UInt16 = 0, username: String = "", password: String = "", websocketToken: String? = nil, _ args: Any...) {
        self.host = host; self.port = port; self.username = username; self.password = password; self.websocketToken = websocketToken
    }

    public var description: String { "CloudBrowserProxyEndpoint(\\(host):\\(port))" }
    public var debugDescription: String { description }
}

public enum CloudBrowserProxyRouting {
    public struct ProxyConfiguration: Sendable { public init(_ args: Any...) {} }
    public static func configuration(endpoint: CloudBrowserProxyEndpoint = CloudBrowserProxyEndpoint(), address: String = "", remoteNetwork: Bool = false, _ args: Any...) -> ProxyConfiguration {
        ProxyConfiguration()
    }
    public static func installWebSocketBridge(endpoint: CloudBrowserProxyEndpoint = CloudBrowserProxyEndpoint(), address: String = "", on webView: Any? = nil, remoteNetwork: Bool = false, _ args: Any...) {}
}

public enum CloudDesktopConnectionScript {
    public static let name = "cmuxCloudDesktopConnection"
    public static let contentWorld = WKContentWorld.world(name: "cmux.cloud.desktop-connection")
    public static func scriptSource(token: String = "") -> String { "" }
}

public final class CloudDesktopConnectionObserver: NSObject, WKScriptMessageHandler {
    public static let name = "cmuxCloudDesktopConnection"
    public static let contentWorld = WKContentWorld.world(name: "cmux.cloud.desktop-connection")
    public static let userScript = WKUserScript(source: "", injectionTime: .atDocumentStart, forMainFrameOnly: false)
    public init(_ args: Any...) {}
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}

public enum CloudDiagnosticFailure: String, Codable, Sendable, Error {
    case authentication, sessionRefresh = "session_refresh", permission, plan
    case rateLimit = "rate_limit", conflict, network, timeout, server, response, unsupported
    case process, `protocol`, notFound = "not_found", placement, resourceLimit = "resource_limit"
    case storage, cancelled, unknown
    public var label: String { "Cloud operation failed." }
}

public final class CloudDisplayCoordinator: @unchecked Sendable {
    public var isAvailable: Bool = false
    public var displaySnapshot: CloudGuestDisplaySnapshot? { nil }

    public init(execute: (@MainActor @Sendable (String, Int) async throws -> VMExecResult)? = nil, _ args: Any...) {}
    public func invalidate() {}
    public func refresh(_ args: Any...) async {}
    public func create(_ args: Any...) async throws -> CloudGuestDisplaySnapshot { CloudGuestDisplaySnapshot() }
    public func stop() {}
}

public struct CloudGuestDisplay: Sendable {
    public var id: String = ""
    public init(_ args: Any...) {}
}

public struct CloudGuestDisplaySnapshot: Sendable {
    public static var unavailableMessage: String { "Display unavailable" }
    public var created: String = ""
    public var displays: [CloudGuestDisplay] { [] }
    public init(_ args: Any...) {}
}

public final class CloudHubPortForwarder: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func close(machineID: String = "", _ args: Any...) {}
}

public enum CloudNetworkPolicyEditError: Error, Sendable, Equatable { case failed }
public enum CloudNetworkPolicyRequestError: Error, LocalizedError, Sendable, Equatable {
    case failed
    case unsupported
    public var errorDescription: String? { "Network policy error" }
}

public enum CloudNotificationDeliveryOutcome: Equatable, Sendable {
    case delivered, declined, suppressed
}

public struct CloudNotificationDeliveryTarget: Equatable, Sendable {
    public var workspaceID: UUID
    public var panelID: UUID?
    public init(workspaceID: UUID = UUID(), panelID: UUID? = nil) {
        self.workspaceID = workspaceID; self.panelID = panelID
    }
}

public enum NotificationReadTarget: Equatable, Sendable {
    case all
    case workspace(UUID = UUID())
    case surface(workspaceID: UUID = UUID(), surfaceID: UUID? = nil)
}

public struct CloudVMNotificationRow: Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var body: String
    public var level: String
    public var createdAtMs: UInt64
    public var terminalID: String?
    public var readBy: [String]
    public init(id: String = "", title: String = "", subtitle: String? = nil, body: String = "", level: String = "", createdAtMs: UInt64 = 0, terminalID: String? = nil, readBy: [String] = []) {
        self.id = id; self.title = title; self.subtitle = subtitle; self.body = body
        self.level = level; self.createdAtMs = createdAtMs; self.terminalID = terminalID; self.readBy = readBy
    }
}

public final class CloudNotificationSyncController: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func linkDidConnect() {}
    public func syncNotifications(from state: CloudVMState) {}
}

@MainActor
public final class CloudNotificationSyncStore {
    public var hasPendingWrites: Bool { false }
    public func drain() async {}
    public init(_ args: Any...) {}
    public func load(machineID: String) -> Any? { nil }
    public func recordRead(_ id: String, for machineID: String) {}
}

public enum CloudEnvDelivery {
    public struct OperationAndCleanupError: Error, LocalizedError {
        public var errorDescription: String? { "Operation and cleanup error" }
        public init(_ args: Any...) {}
    }
    public enum Outcome: Equatable, Sendable {
        case ok(keys: Int = 0, reported: String? = nil)
        case failed(String)
    }
    public struct Entry: Equatable, Sendable {
        public let key: String
        public let value: String
        public init(key: String = "", value: String = "") { self.key = key; self.value = value }
    }
    public static let receiverTitle = "cmux env"
    public enum DeliveryError: Error, LocalizedError {
        case failed, workspaceCleanupFailed(String)
        public var errorDescription: String? { "Delivery error" }
    }
    public static let readyMarker = "CMUX-ENV-READY"
    public static let readyTimeoutMs = 1000
    public static let resultPattern = "RESULT"
    public static let resultTimeoutMs = 1000
    public static func payload(_ args: Any...) -> Any? { nil }
    public static var receiverCommand: [String] { ["/bin/sh"] }
    public static func receiverCommand(path: String = "", mode: String = "") -> [String] { ["/bin/sh"] }
    public static let maxPayloadBytes = 256 * 1024
    public static func chunks(_ wire: Data, size: Int = 1024) -> [Data] { [wire] }
    public static func chunks(_ data: Data) -> [Data] { [data] }
    public static func isValidKey(_ key: String) -> Bool { true }
    public static func wire(_ entries: [Entry]) -> Data { Data() }
    public static func wire(_ dict: [String: String]) -> Data { Data() }
    public static func wire(_ payload: Any? = nil, _ args: Any...) -> Data { Data() }
    public static func requireReady(_ ready: Any? = nil, machineID: String = "", _ args: Any...) throws {}
    public static func requireOutcome(_ result: Any?, expectedEntries: Any? = nil) throws -> Outcome { .ok() }
    public static func removeReceiverResources(
        terminalIDs: [String] = [],
        discoverTerminalIDs: (() async throws -> [String])? = nil,
        closeTerminal: ((String) async throws -> Void)? = nil,
        closeWorkspace: (() async throws -> Void)? = nil,
        _ args: Any...
    ) async throws {}
    public static func withReceiverWorkspace<Result>(
        createWorkspace: () async throws -> String = { "" },
        closeWorkspace: (String) async throws -> Void = { _ in },
        operation: (String) async throws -> Result
    ) async rethrows -> Result {
        let ws = try await createWorkspace()
        return try await operation(ws)
    }
}

public enum CloudFileDelivery {
    public struct OperationAndCleanupError: Error, LocalizedError {
        public var errorDescription: String? { "Operation and cleanup error" }
        public init(_ args: Any...) {}
    }
    public enum DeliveryError: Error, LocalizedError {
        case fileMissing, failed, workspaceCleanupFailed(String)
        public var errorDescription: String? { "Delivery error" }
    }
    public enum Outcome: Equatable, Sendable {
        case ok(bytes: Int, path: String?, mode: String?)
        case failed(String)
    }
    public static let maxPayloadBytes = 256 * 1024
    public static let defaultMode = "600"
    public static let readyMarker = "READY"
    public static let readyTimeoutMs = 1000
    public static let resultPattern = "RESULT"
    public static let resultTimeoutMs = 1000
    public struct Request: Equatable, Sendable {
        public let path: String
        public let mode: String
        public let data: Data
        public init(path: String = "", mode: String = "600", data: Data = Data()) {
            self.path = path; self.mode = mode; self.data = data
        }
    }
    public static func isValidMode(_ mode: String) -> Bool { true }
    public struct FilePayload: Sendable {
        public var path: String = ""
        public var mode: String = "600"
        public var data: Data = Data()
        public init(path: String = "", mode: String = "600", data: Data = Data()) {
            self.path = path; self.mode = mode; self.data = data
        }
    }
    public static let receiverTitle = "cmux file"
    public static var receiverCommand: [String] { ["/bin/sh"] }
    public static func receiverCommand(path: String = "", mode: String = "") -> [String] { ["/bin/sh"] }
    public static func wire(_ data: Data) -> Data { data }
    public static func wire(_ payload: FilePayload) -> Data { payload.data }
    public static func wire(_ payload: Any? = nil, _ args: Any...) -> Data { Data() }
    public static func requireReady(_ ready: Any? = nil, machineID: String = "", _ args: Any...) throws {}
    public static func requireOutcome(_ result: Any?, expectedBytes: Int = 0) throws -> Outcome { .ok(bytes: expectedBytes, path: "", mode: "600") }
    public static func validate(_ args: Any...) throws {}
    public static func withReceiverWorkspace<Result>(
        createWorkspace: () async throws -> String = { "" },
        closeWorkspace: (String) async throws -> Void = { _ in },
        operation: (String) async throws -> Result
    ) async rethrows -> Result {
        let ws = try await createWorkspace()
        return try await operation(ws)
    }
    public static func removeReceiverResources(_ args: Any...) async throws {}
}

public enum CloudDisabledReason: Sendable, Equatable {
    case accountLoggedOut, disabledByPolicy, networkOffline
    public static let socketErrorCode = "cloud_disabled"
    public static var disabledMessage: String { "Cloud Machines are disabled." }
}

public enum RemoteDisabledReason: Sendable, Equatable {
    case featureDisabled
    public static var disabledMessage: String { "Remote connections are disabled." }
}

public enum RelayNetworkingDisabledReason: Sendable, Equatable {
    case featureDisabled
    public static var disabledMessage: String { "Relay networking is disabled." }
}

public enum AuthEnvironment: Sendable {
    public static var callbackScheme: String { "wmux" }
    public static var appWebOrigin: URL { URL(string: "http://localhost")! }
    public static var appSessionHandoffOrigin: URL { URL(string: "http://localhost")! }
    public static var appPricingURL: URL { URL(string: "http://localhost")! }
    public static var vmAPIBaseURL: URL { URL(string: "http://localhost")! }
    public static var billingCheckoutURL: URL { URL(string: "http://localhost")! }
    public static var billingPortalURL: URL { URL(string: "http://localhost")! }
    public static var apiBaseURL: URL { URL(string: "http://localhost")! }
    public static var websiteOrigin: URL { URL(string: "http://localhost")! }
    public static var callbackURL: URL { URL(string: "wmux://callback")! }
    public static var pricingURL: URL { URL(string: "http://localhost")! }
    public static var debugCloudDiagnosticsBaseURL: URL? { nil }
    public static var stackBaseURL: URL { URL(string: "http://localhost")! }
    public static var stackProjectID: String { "" }
    public static var stackPublishableClientKey: String { "" }
    public static var pushAPIBaseURL: URL { URL(string: "http://localhost")! }
    public static var deviceRegistryAPIBaseURL: URL { URL(string: "http://localhost")! }
    public static func signInURL(_ args: Any...) -> URL { URL(string: "http://localhost")! }
}

public protocol CmxIrohSettingsControlling: AnyObject, Sendable {}
public struct DiagnosticTerminalTraceID: Sendable, Equatable { public init(_ args: Any...) {} }

public struct WorkspacePresenceParticipant: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String?
    public var avatarURL: URL?
    public var isActive: Bool

    public init(id: String = UUID().uuidString, displayName: String? = nil, avatarURL: URL? = nil, isActive: Bool = true, _ args: Any...) {
        self.id = id; self.displayName = displayName; self.avatarURL = avatarURL; self.isActive = isActive
    }
}

public final class WorkspacePresenceStore: @unchecked Sendable {
    public init(_ args: Any...) {}
    public func participants(for workspaceID: UUID) -> [WorkspacePresenceParticipant] { [] }
}

public struct AgentChatChildRun: Sendable, Equatable {
    public let id: String
    public var label: String?
    public let startedAt: Date
    public var endedAt: Date?
    public init(id: String = UUID().uuidString, label: String? = nil, startedAt: Date = Date(), endedAt: Date? = nil) {
        self.id = id; self.label = label; self.startedAt = startedAt; self.endedAt = endedAt
    }
    public var isRunning: Bool { endedAt == nil }
    public static let settledRetention: TimeInterval = 15 * 60
    public static let capacity = 16
}

public struct AgentChatSessionRecord: Sendable {
    public let sessionID: String
    public let agentKind: ChatAgentKind
    public var workspaceID: String?
    public var surfaceID: String?
    public var workingDirectory: String?
    public var transcriptPath: String?
    public var state: ChatAgentState
    public var hasHookLifecycleState: Bool = false
    public var endedAt: Date?
    public var lastActivityAt: Date
    public var children: [AgentChatChildRun] = []
    public var title: String?
    public var pid: Int?
    public var hookStoreSessionID: String?
    public var version: Int = 0

    public init(
        sessionID: String = "",
        agentKind: ChatAgentKind = .other("agent"),
        workspaceID: String? = nil,
        surfaceID: String? = nil,
        workingDirectory: String? = nil,
        transcriptPath: String? = nil,
        state: ChatAgentState = .idle,
        hasHookLifecycleState: Bool = false,
        endedAt: Date? = nil,
        lastActivityAt: Date = Date(),
        children: [AgentChatChildRun] = [],
        title: String? = nil,
        pid: Int? = nil,
        hookStoreSessionID: String? = nil,
        version: Int = 0,
        _ args: Any...
    ) {
        self.sessionID = sessionID; self.agentKind = agentKind; self.workspaceID = workspaceID; self.surfaceID = surfaceID
        self.workingDirectory = workingDirectory; self.transcriptPath = transcriptPath; self.state = state
        self.hasHookLifecycleState = hasHookLifecycleState; self.endedAt = endedAt; self.lastActivityAt = lastActivityAt
        self.children = children; self.title = title; self.pid = pid; self.hookStoreSessionID = hookStoreSessionID; self.version = version
    }

    public var hookStoreLookupSessionID: String { hookStoreSessionID ?? sessionID }
    public mutating func rememberHookStoreSessionID(_ id: String) {
        if id != sessionID { hookStoreSessionID = id }
    }
    public mutating func setHookLifecycleState(_ nextState: ChatAgentState) {
        state = nextState
        hasHookLifecycleState = true
    }
}

public struct AgentChatSessionNotificationMetadata: Sendable, Equatable {
    public var sessionID: String = ""
    public var agentKind: ChatAgentKind = .other("agent")
    public var iconName: String = "terminal"
    public var displayName: String = "Agent"
    public init(sessionID: String = "", agentKind: ChatAgentKind = .other("agent"), iconName: String = "terminal", displayName: String = "Agent", _ args: Any...) {
        self.sessionID = sessionID; self.agentKind = agentKind; self.iconName = iconName; self.displayName = displayName
    }
}

public enum MobileHostIdentity: Sendable {
    public static func deviceID(_ args: Any...) -> String { "local-device" }
    public static func deviceIDIfReady() -> String? { "local-device" }
    public static func baseDisplayName(_ args: Any...) -> String? { "wmux" }
    public static func instanceDisplayName(_ args: Any...) -> String? { "wmux" }
    public static func prewarm() async {}
}

public final class MobileHostIdentitySyncManager: @unchecked Sendable {
    public static let shared = MobileHostIdentitySyncManager()
    public var deviceID: String { "" }
    public init() {}
    public func start() {}
}

public struct MobileTerminalInputAcknowledgement: Equatable, Sendable {
    public enum Status: UInt8, Equatable, Sendable { case applied = 1, duplicate = 2, gap = 3, targetClosed = 4 }
    public var sequence: UInt64
    public var status: Status
    public var expectedSequence: UInt64
    public init(sequence: UInt64 = 0, status: Status = .applied, expectedSequence: UInt64 = 0) {
        self.sequence = sequence; self.status = status; self.expectedSequence = expectedSequence
    }
}

public struct MobileBrowserDialogButton: Codable, Equatable, Sendable {
    public enum Role: String, Codable, Sendable { case normal, cancel, destructive, `default` }
    public var id: String
    public var label: String
    public var role: Role
    public init(id: String = "", label: String = "", role: Role = .normal) {
        self.id = id; self.label = label; self.role = role
    }
}

public struct MobileBrowserDialogTextField: Codable, Equatable, Sendable {
    public var placeholder: String?
    public var initialValue: String?
    public var isSecure: Bool
    public var initial: String? { initialValue }
    public init(placeholder: String? = nil, initial: String? = nil, initialValue: String? = nil, isSecure: Bool = false, secure: Bool = false) {
        self.placeholder = placeholder; self.initialValue = initialValue ?? initial; self.isSecure = isSecure || secure
    }
}

public struct MobileBrowserViewport: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var scale: Double
    public init(width: Int = 0, height: Int = 0, scale: Double = 1.0, _ args: Any...) {
        self.width = width; self.height = height; self.scale = scale
    }
}

public enum MobileBrowserDialogKind: String, Codable, Sendable {
    case insecureHTTP = "insecure_http"
    case javaScriptAlert = "javascript_alert"
    case javaScriptConfirm = "javascript_confirm"
    case javaScriptPrompt = "javascript_prompt"
    case httpBasicAuthentication = "http_basic_authentication"
    case mediaCapturePermission = "media_capture_permission"
    case fileUpload = "file_upload"
    case clientCertificate = "client_certificate"
}

public struct MobileBrowserDialogEvent: Codable, Equatable, Sendable {
    public var panelID: String
    public var dialogID: String
    public var kind: MobileBrowserDialogKind
    public var title: String?
    public var message: String?
    public var host: String?
    public var buttons: [MobileBrowserDialogButton]
    public var textField: MobileBrowserDialogTextField?
    public var informational: Bool
    public init(
        panelID: String = "",
        dialogID: String = UUID().uuidString,
        kind: MobileBrowserDialogKind = .javaScriptAlert,
        title: String? = nil,
        message: String? = nil,
        host: String? = nil,
        buttons: [MobileBrowserDialogButton] = [],
        textField: MobileBrowserDialogTextField? = nil,
        informational: Bool = false,
        _ args: Any...
    ) {
        self.panelID = panelID; self.dialogID = dialogID; self.kind = kind
        self.title = title; self.message = message; self.host = host
        self.buttons = buttons; self.textField = textField; self.informational = informational
    }
}

public struct MobileBrowserDialogResolvedEvent: Sendable, Equatable {
    public var dialogID: String
    public var buttonID: String
    public var text: String?
    public init(dialogID: String = "", buttonID: String = "", text: String? = nil) {
        self.dialogID = dialogID; self.buttonID = buttonID; self.text = text
    }
}

public struct MobileBrowserDialogRespondParameters: Codable, Equatable, Sendable {
    public let panelID: String
    public let dialogID: String
    public let buttonID: String
    public let text: String?
    public init(panelID: String = "", dialogID: String = "", buttonID: String = "", text: String? = nil, _ args: Any...) {
        self.panelID = panelID; self.dialogID = dialogID; self.buttonID = buttonID; self.text = text
    }
    public init(panelID: UUID, dialogID: String = "", buttonID: String = "", text: String? = nil, _ args: Any...) {
        self.panelID = panelID.uuidString; self.dialogID = dialogID; self.buttonID = buttonID; self.text = text
    }
}

@MainActor
public final class MobileBrowserDialogBroker {
    public typealias Resolver = @MainActor (_ buttonID: String, _ text: String?) -> Void
    public typealias Dismissal = @MainActor () -> Void

    public let panelID: String
    public var onPresented: (@MainActor (MobileBrowserDialogEvent) -> Void)?
    public var onResolved: (@MainActor (MobileBrowserDialogResolvedEvent) -> Void)?
    public var currentDialog: MobileBrowserDialogEvent? = nil
    public var pendingDialogs: [MobileBrowserDialogEvent] = []

    public init(panelID: String = "", _ args: Any...) {
        self.panelID = panelID
    }

    @discardableResult
    public func begin(
        kind: MobileBrowserDialogKind = .javaScriptAlert,
        title: String? = nil,
        message: String? = nil,
        host: String? = nil,
        buttons: [MobileBrowserDialogButton] = [],
        textField: MobileBrowserDialogTextField? = nil,
        informational: Bool = false,
        resolve: @escaping Resolver = { _, _ in }
    ) -> MobileBrowserDialogEvent {
        MobileBrowserDialogEvent(
            panelID: panelID,
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

    public func attachDismissal(dialogID: String, dismissal: @escaping Dismissal = {}) {}
    @discardableResult public func respond(_ response: MobileBrowserDialogRespondParameters) -> Bool { true }
    @discardableResult public func resolveFromMac(dialogID: String, action: @escaping @MainActor () -> Void = {}) -> Bool {
        action()
        return true
    }
    public func resolveAll(where predicate: (MobileBrowserDialogEvent) -> Bool = { _ in true }) {}
}

public struct MobileWorkspaceDescriptionProjection: Equatable, Sendable {
    public let value: String?
    public let isTruncated: Bool
    public init(value: String?, isTruncated: Bool) {
        self.value = value; self.isTruncated = isTruncated
    }
}

public enum MobileWorkspaceMetadataLimits {
    public static let customDescriptionMaxUTF8Bytes = 4096
    public static let customDescriptionsAggregateMaxJSONEscapedUTF8Bytes = 1 * 1024 * 1024
    public static let customColorMaxUTF8Bytes = 64
    public static func normalizedCustomDescription(_ description: String?) -> String? { description }
    public static func boundedCustomDescription(_ description: String?) -> String? { description }
    public static func projectedCustomDescription(_ description: String?) -> MobileWorkspaceDescriptionProjection {
        MobileWorkspaceDescriptionProjection(value: description, isTruncated: false)
    }
    public static func projection(_ projection: MobileWorkspaceDescriptionProjection, constrainedToJSONEscapedUTF8Budget remainingBudget: inout Int) -> MobileWorkspaceDescriptionProjection {
        projection
    }
    public static func jsonEscapedUTF8ByteCount(_ value: String) -> Int { value.utf8.count }
}

public enum MobileTerminalScrollbackPreference {
    public static let defaultRows = 4000
    public static let maximumRows = 20000
    public static func clamped(_ rows: Int) -> Int { min(max(rows, 0), maximumRows) }
    public static func resolve(from defaults: UserDefaults = .standard) -> Int { defaultRows }
}

public struct MobileViewportApplyGovernor {
    public enum Target: Equatable {
        case cap(columns: Int, rows: Int)
        case uncapped
    }
    public enum Decision: Equatable {
        case apply(Target)
        case stage(Target, scheduleFlush: Bool)
        case drop
    }
    public private(set) var applied: Target?
    public private(set) var staged: Target?
    public private(set) var flushScheduled = false

    public init() {}
    public mutating func request(_ target: Target, immediate: Bool = false) -> Decision {
        if target == applied { return .drop }
        applied = target
        return .apply(target)
    }
    public mutating func flush() -> Target? {
        flushScheduled = false
        return applied
    }
}

public enum MobileTerminalReplayViewportFence {
    public static func accepts(capturedColumns: Int, capturedRows: Int, expectedColumns: Int, expectedRows: Int) -> Bool { true }
}

// MARK: - Core Protocols, Extensions & Helpers

extension CloudVMCursor {
    public init() { self.init(generation: "", revision: 0) }
}

extension SurfaceResource {
    public func catalogPrecedes(_ other: SurfaceResource) -> Bool {
        if machine != other.machine { return machine.rawValue < other.machine.rawValue }
        if kind != other.kind { return kind.rawValue < other.kind.rawValue }
        let lhs = remoteWorkspace?.index ?? -1, rhs = other.remoteWorkspace?.index ?? -1
        if lhs != rhs { return lhs < rhs }
        return id.key < other.id.key
    }
    public var cloudProcessDisplayTitle: String { title }
}

extension CloudMachineAccessLoss {
    public var isMachineScoped: Bool { self != .signInRevoked }
    public init?(error: Error) {
        if case VMClientError.httpStatus(let status, let body) = error {
            self.init(status: status, body: body)
        } else {
            return nil
        }
    }
    public init?(status: Int, body: String) {
        if status == 404 { self = .notFound }
        else if status == 403 { self = .forbidden }
        else if status == 409 { self = .ownerMismatch }
        else { return nil }
    }
}

extension CloudGuestDisplay {
    public static func privateDesktopURL(privateAddress: String, port: Int = 6901) -> String {
        "http://\(privateAddress):\(port)/vnc.html"
    }
}

extension CloudGuestDisplaySnapshot {
    // removed duplicate unavailableMessage
}

extension CloudTuiClientPaths {
    public static func clientURL() -> URL? { nil }
    public func notificationClientID() -> String { "mac-default" }
    public static let carrierDeviceMarker = "carrier"
    public func saveDeviceFingerprint(_ fp: String, for machineID: String) {}
    public func deviceFingerprint(for machineID: String) -> String? { nil }
    public var stateDir: URL { Self.stateDirectoryURL() }
    public var stateDirectory: URL { Self.stateDirectoryURL() }
}

extension CloudVMPanelAuthState {
    public var allowsAuthenticatedOperation: Bool { self == .signedIn }
}

extension CloudActivationPolicy {
    public static func live(_ args: Any...) -> CloudActivationPolicy { CloudActivationPolicy() }
}

extension CloudRequestBudget {
    public static let live = CloudRequestBudget()
    public func withBudget<Result>(seconds: TimeInterval? = nil, _ operation: () async throws -> Result) async rethrows -> Result {
        try await operation()
    }
}

extension CloudWireGuardHub {
    public nonisolated func terminateForAppQuit() {}
    public func prepareForCloudUse(allowWhenCloudDisabled: Bool = false, expectedTeamScope: String? = nil, _ args: Any...) async {}
}

extension CloudHubPortForwarder {
    public convenience init(dialer: any CloudHubDialing = CloudWireGuardHubDialer(), _ args: Any...) { self.init() }
}

extension CloudNetworkPolicyEditError: LocalizedError {
    public var errorDescription: String? { "Invalid network policy edit" }
}

// removed redundant CloudNetworkPolicyRequestError: LocalizedError

extension RemotePTYLifecycleCommitLease {
    public func beginReadinessDeliveryAdmission() -> RemotePTYLifecycleReadinessDeliveryAdmission { .acquired }
    public func finishReadinessDeliveryAdmission(succeeded: Bool) {}
}

public enum RemotePTYLifecycleReadinessDeliveryAdmission: Sendable {
    case acquired, inFlight, alreadyCompleted, stale
}

extension CloudTerminalMutationQueue {
    public func run<Value: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> Value) async throws -> Value {
        try await operation()
    }
    public func runCommitted<Value: Sendable>(_ operation: @escaping @MainActor @Sendable () async throws -> Value) async throws -> Value {
        try await operation()
    }
    public func cancelAll() {}
    public func waitForIdle() async {}
}

extension CloudTerminalCreationRequest {
    public var correlationArgument: String? { nil }
    public func bind(remoteWorkspaceID: String) {}
    public func prepare(using runner: any CloudTuiCommandRunning, socketPath: String = "") async throws -> WmuxTuiSnapshotParser.CreatedTerminalPath? {
        nil
    }
}

extension WmuxTuiSnapshotParser {
    public nonisolated static func tabPlacement(from data: Data, tabID: String) async -> (workspaceID: String?, revision: String)? {
        nil
    }
    public nonisolated static func terminalProjectionTarget(
        from data: Data,
        preferringWorkspace workspaceID: String? = nil
    ) async -> (target: CloudTuiTerminalProjectionTarget, revision: String?)? {
        (CloudTuiTerminalProjectionTarget(), "1")
    }
// removed duplicate terminalPlacement
    public nonisolated static func placedTab(
        from data: Data,
        at target: CloudTuiTerminalProjectionTarget,
        tabID: String? = nil,
        terminalID: String? = nil
    ) async -> SurfaceRemotePlacement? {
        SurfaceRemotePlacement(workspaceID: target.workspaceID, tabID: tabID ?? "tab_1")
    }
// removed duplicate applyingWithImpact
}

extension CloudTuiRequests {
    public static func keysArguments(socketPath: String = "", terminalID: String = "", keys: [String] = []) -> CloudTuiRequest { CloudTuiRequest("terminal.input.keys", mutation: true) }
    public static func writeBytes(terminalID: String = "", data: Data = Data()) -> CloudTuiRequest { CloudTuiRequest("terminal.input.write", mutation: true) }
    public static func screenReadArguments(socketPath: String = "", terminalID: String = "") -> CloudTuiRequest { CloudTuiRequest("terminal.screen.read") }
    public static func screenWaitArguments(socketPath: String = "", terminalID: String = "", pattern: String = "", timeoutMs: Int? = nil) -> CloudTuiRequest { CloudTuiRequest("terminal.wait") }
    public static func processWaitArguments(socketPath: String = "", terminalID: String = "", timeoutMs: Int? = nil) -> CloudTuiRequest { CloudTuiRequest("terminal.wait_exit") }
    public static func outputReadArguments(socketPath: String = "", terminalID: String = "", after: Int? = nil, maxBytes: Int? = nil) -> CloudTuiRequest { CloudTuiRequest("terminal.output_read") }
    public static func putCloudDisplayMembershipProjection(_ args: Any...) -> CloudTuiRequest { CloudTuiRequest("membership.put", mutation: true) }
}

extension VMClient {
    public func openAttach(id: String, requireDaemon: Bool = false, sessionId: String? = nil, attachmentId: String? = nil, title: String? = nil, teamID: String? = nil) async throws -> VMAttachEndpoint {
        .websocket(VMWebSocketPtyEndpoint())
    }
}

public struct VMWebSocketDaemonEndpoint: Sendable {
    public let url: String
    public let headers: [String: String]
    public let token: String
    public let sessionId: String
    public let expiresAtUnix: Int64
    public init(url: String = "", headers: [String: String] = [:], token: String = "", sessionId: String = "", expiresAtUnix: Int64 = 0) {
        self.url = url; self.headers = headers; self.token = token; self.sessionId = sessionId; self.expiresAtUnix = expiresAtUnix
    }
}

public struct VMWebSocketPtyEndpoint: Sendable {
    public let transport: String
    public let url: String
    public let headers: [String: String]
    public let token: String
    public let sessionId: String
    public let attachmentId: String
    public let expiresAtUnix: Int64
    public let daemon: VMWebSocketDaemonEndpoint?
    public init(transport: String = "ws", url: String = "", headers: [String: String] = [:], token: String = "", sessionId: String = "", attachmentId: String = "", expiresAtUnix: Int64 = 0, daemon: VMWebSocketDaemonEndpoint? = VMWebSocketDaemonEndpoint()) {
        self.transport = transport; self.url = url; self.headers = headers; self.token = token; self.sessionId = sessionId; self.attachmentId = attachmentId; self.expiresAtUnix = expiresAtUnix; self.daemon = daemon
    }
}

public struct VMSSHEndpoint: Sendable { public init(_ args: Any...) {} }

public enum VMAttachEndpoint: Sendable {
    case ssh(VMSSHEndpoint)
    case websocket(VMWebSocketPtyEndpoint)
}



// MARK: - Final Integration Additions
import Network
import WebKit

extension CloudBrowserRouting {
    @MainActor
    public static func configuration(endpoint: CloudBrowserProxyEndpoint, address: String, remoteNetwork: Bool = false) -> ProxyConfiguration {
        ProxyConfiguration(httpCONNECTProxy: .hostPort(host: .init(endpoint.host), port: .init(rawValue: endpoint.port)!))
    }
    @MainActor
    public static func installWebSocketBridge(endpoint: CloudBrowserProxyEndpoint, address: String, on webView: WKWebView, remoteNetwork: Bool = false) {}
    @MainActor
    public static func favicon(url: URL, webView: WKWebView) async throws -> (Data, URLResponse) {
        throw URLError(.badServerResponse)
    }
}

extension CloudHubPortForwarder {
    public func closeAll() {}
}

extension CloudMachineLinkManager {
    public static func isAsleepStatus(_ status: Any?) -> Bool { false }
}

extension SurfaceLinkState {
    public static let ready = SurfaceLinkState.connected
}

public struct MobileTaskFilesystemJobQuota: Sendable {
    public init() {}
}

public struct MobileTaskModelDiscoveryResult: Sendable {
    public struct Model: Sendable {
        public struct Effort: Sendable {
            public var id: String = ""
            public var displayName: String = ""
            public var description: String? = nil
            public init(id: String = "", displayName: String = "", description: String? = nil) {
                self.id = id; self.displayName = displayName; self.description = description
            }
        }
        public var id: String = ""
        public var displayName: String = ""
        public var defaultEffortID: String? = nil
        public var efforts: [Effort] = []
        public init(id: String = "", displayName: String = "", defaultEffortID: String? = nil, efforts: [Effort] = []) {
            self.id = id; self.displayName = displayName; self.defaultEffortID = defaultEffortID; self.efforts = efforts
        }
    }
    public var models: [Model] = []
    public var defaultModel: Model? = nil
    public var source: String = ""
    public var error: String? = nil
    public init(models: [Model] = [], defaultModel: Model? = nil, source: String = "", error: String? = nil) {
        self.models = models; self.defaultModel = defaultModel; self.source = source; self.error = error
    }
}


public struct MachinePlanSnapshot: Sendable {
    public init(activeCount: Int = 0, maxActiveVms: Int? = nil, planId: String? = nil, freeAccessWindowDays: Int? = nil, freeAccessExpiresAt: Any? = nil, _ args: Any...) {}
}
public protocol RemoteTransferCancelling { var cancellationError: any Error { get } }

extension CurrentWorkInput {
    public typealias WorkspaceFacts = CurrentWorkObservation.WorkspaceFacts
}

@MainActor
public final class CloudBannerDismissalStore {
    public init(defaults: UserDefaults = .standard) {}
    public func isDismissed(id: String, signature: String) -> Bool { false }
    public func dismiss(id: String, signature: String) {}
    public func clear(id: String) {}
}

extension VMCapabilities {
    public var canFork: Bool { fork }
}


extension CurrentWorkSnapshot {
    public func jsonObject() -> [String: Any] { [:] }
}

extension CloudWireGuardHub {
    public func stop() async {}
}

extension CloudGuestDisplay {
    public func resource(on machine: SurfaceMachineID, address: String?) -> SurfaceResource {
        SurfaceResource(id: SurfaceResourceID(machine: machine, kind: .display, key: "display"), title: "Display", detail: "noVNC", lifecycle: .running)
    }
}

extension CloudActivationPolicy {
    public var allowsBackgroundCloudWork: Bool { false }
}

extension DiagnosticTerminalTraceID {
    public init(stringValue: String) { self.init() }
    public var stringValue: String { "" }
}

public enum CloudImagePasteError: Error, Sendable { case unavailable }

extension CloudWireGuardHub {
    public func prepareForCloudUse(allowWhenCloudDisabled: Bool = true, expectedTeamScope: Any? = nil, _ args: Any...) async {}
}


