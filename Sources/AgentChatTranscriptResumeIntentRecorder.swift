import CmuxAgentChat
import CmuxAuthRuntime
import CmuxCloud
import CmuxCloudTui
import CmuxControlSocket
import CmuxFoundation
import CmuxSettingsUI
import CmuxProductAnalytics
import CmuxMobileHost
import CmuxSurfaceCatalogModel
import CmuxTerminal
import CmuxTerminalCore
import CMUXMobileCore
import Foundation
import Observation
import SwiftUI

/// Bridges structured resume bindings into the live transcript registry.
struct AgentChatTranscriptResumeIntentRecorder: AgentChatResumeIntentRecording {
    @MainActor
    func record(_ intent: AgentChatResumeIntent) {
        AgentChatTranscriptService.recordResumeIntent(
            sessionID: intent.sessionID,
            source: intent.source,
            surfaceID: intent.surfaceID,
            workspaceID: intent.workspaceID,
            workingDirectory: intent.workingDirectory
        )
    }
}

@MainActor
final class HostAccountFlow: CmuxSettingsUI.AccountFlow, @unchecked Sendable {
    var currentIdentity: AccountIdentity? { nil }
    var availableTeams: [AccountTeamSummary] { [] }
    var selectedTeamID: String? { nil }
    func selectTeam(id: String?) async throws {}
    var isWorkingOnAuth: Bool { false }
    var signInIsSlow: Bool { false }
    func startSignIn() {}
    func openSignInInDefaultBrowser() {}
    func signOut() async {}
    func refreshCurrentUser() async {}

    var isAuthenticated: Bool { false }
    var confirmedTeamID: String? { nil }
    func startSignIn(from window: Any?) {}
}

@MainActor
final class MacAuthComposition: Sendable {
    final class BrowserAppSession: @unchecked Sendable {
        func register(_ panel: Any) {}
        func request(destinationURL: URL) async -> BrowserAppSessionRequestOutcome { .notAuthenticated }
        func isCurrent(generation: Any? = nil, authSessionGeneration: Any? = nil) -> Bool { false }
    }
    let browserAppSession = BrowserAppSession()

    typealias TeamScope = AuthenticatedTeamScope
    final class Coordinator: @unchecked Sendable {
        var authenticatedTeamScope: AuthenticatedTeamScope? = nil
        var isAuthenticated: Bool { false }
    }
    let coordinator = Coordinator()

    typealias AccountFlow = HostAccountFlow
    let accountFlow = HostAccountFlow()

    var callbackRouter: AuthCallbackRouter { AuthCallbackRouter() }
    func start() {}
}

@MainActor
@Observable
final class CloudActivationCoordinator {
    enum Failure: Equatable, Sendable {
        case requiresPro
        case signInRequired
        case serviceUnavailable
    }

    enum State: Equatable, Sendable {
        case disabled
        case enabling
        case enabled
        case failed(Failure)
        case cancelled
        case unavailable
    }

    var state: State = .unavailable
    var isPreparing: Bool = false

    init(
        prepare: Any? = nil,
        cleanup: Any? = nil,
        analytics: ProductAnalytics = .disabled
    ) {}

    static func unconfigured() -> CloudActivationCoordinator {
        CloudActivationCoordinator()
    }

    func enable() {}
    func cancel() {}
    func retry() {}
    func disable() {}
    func activationChanges() -> AsyncStream<State> {
        AsyncStream { $0.yield(.unavailable); $0.finish() }
    }
}

enum MobileRemoteControlPolicy {
    static var isDisabled: Bool { true }
    static func isDeviceDiscoveryDisabled() -> Bool { true }
    static func isIncomingAccessDisabled() -> Bool { true }
}

enum DevicesFeature {
    static var isEnabled: Bool { false }
    static func isAvailable(defaults: UserDefaults = .standard, policy: Any? = nil) -> Bool { false }
    static func localOptIn(defaults: UserDefaults = .standard) -> Bool { false }
}

enum ManagedFileTransferPolicy {
    static var isDisabled: Bool { false }
    static var isEnabled: Bool { true }
    static var disabledMessage: String { "File transfer disabled." }
    static func isRefusal(_ error: Error) -> Bool { false }
    static func presentRefusal() {}
    static func refusalError() -> NSError { NSError(domain: "cmux.filetransfer", code: 1, userInfo: [NSLocalizedDescriptionKey: "File transfer disabled"]) }
}

final class CloudImagePasteInputLease: @unchecked Sendable {
    init(view: Any? = nil, operation: Any? = nil) {}
    func finish() {}
}

extension NSNotification.Name {
    static let fileExplorerStyleDidChange = NSNotification.Name("cmux.fileExplorerStyleDidChange")
}

struct CloudWorkspaceGroupDestination: @unchecked Sendable {
    var tabManager: TabManager?
    var groupId: UUID?
    var placement: Any?
    var referenceWorkspaceId: UUID?
    var initialWorkspaceId: UUID?
    init(tabManager: TabManager? = nil, groupId: UUID? = nil, placement: Any? = nil, referenceWorkspaceId: UUID? = nil, initialWorkspaceId: UUID? = nil) {
        self.tabManager = tabManager
        self.groupId = groupId
        self.placement = placement
        self.referenceWorkspaceId = referenceWorkspaceId
        self.initialWorkspaceId = initialWorkspaceId
    }
    func apply(workspaceID: UUID) {}
}

@MainActor
final class CloudTuiManualMirrorSession: Sendable {
    final class ImagePasteStub: Sendable {
        func beginPreparation() throws -> Int { 0 }
        func endPreparation() {}
        func requireAvailable() throws {}
        func paste(_ image: Any, generation: Int) async throws {}
    }

    static var localSharingIdentity: String { "" }
    var phase: CloudTuiManualMirrorPhase = .idle
    var attachmentCorrelationID: String = ""
    var machineID: String = ""
    var terminalID: String = ""
    var allowsAutomaticReconnect: Bool = false
    var connectionPresentation: CloudTerminalReconnectOverlayPolicy.Presentation? { nil }
    var imagePaste: ImagePasteStub = ImagePasteStub()

    init(
        machineID: Any? = nil,
        terminalID: Any? = nil,
        remoteSurfaceID: Any? = nil,
        operations: Any? = nil,
        creationAttachment: Any? = nil,
        resolveLegacySurfaceID: Any? = nil
    ) {}

    func retryConnection() -> Bool { false }
    func cancelConnectionAttempt() -> Bool { false }
    func stop(reason: Any = "") {}
    func scheduleFidelityCheck() {}
    func markSurfaceResolutionUnavailable() {}
}

struct DeviceTerminalInputRouter: Sendable {
    func enqueue(_ data: Any) {}
}

final class MobileTerminalByteTee: @unchecked Sendable {
    static let shared = MobileTerminalByteTee()

    struct ReplayState {
        var seq: UInt64 = 0
        var data: Data = Data()
    }
    struct RenderCaptureIdentity {
        var epoch: UInt64 = 0
        var revision: UInt64 = 0
    }

    func dropSurface(surfaceID: UUID) {}
    func append(surfaceID: UUID, bytes: UnsafeBufferPointer<UInt8>) {}
    func replayState(surfaceID: UUID) -> ReplayState? { nil }
    func currentRenderCaptureIdentity(surfaceID: UUID) -> RenderCaptureIdentity { .init() }
    func nextRenderCaptureIdentity(surfaceID: UUID) -> RenderCaptureIdentity { .init() }
    func performMobileInput(
        surfaceID: UUID,
        sequence: UInt64?,
        receivedAtMicros: UInt64? = nil,
        operation: () -> TerminalSurface.InputSendResult
    ) -> TerminalSurface.InputSendResult {
        operation()
    }
    func currentSequence(surfaceID: UUID) -> UInt64? { nil }
}

@MainActor
final class CloudTuiManualMirrorHandshake: Sendable {
    init(identity: Any? = nil) {}
    func cancel() {}
    func close() {}
}

@MainActor
final class DeviceSurfaceProviderRegistry: Sendable {
    func configure(auth: Any? = nil, catalog: SurfaceCatalog = .shared, authorization: Any? = nil) {}
    func evaluate() {}
}

@MainActor
final class ConnectivityInvalidationSubscriberCoordinator: Sendable {
    func appWillTerminate() {}
    func configure(auth: Any? = nil) {}
}

@MainActor
final class WorkspacePresenceController: Sendable {
    func refreshSelection() {}
    func configure(auth: Any? = nil) {}
}

@MainActor
final class CloudWorkspaceOperationController: Sendable {
    var isCurrentlyAvailable: Bool { false }
    init(isAvailable: Any? = nil) {}
    func cancelAll() {}
    @discardableResult
    func start(key: String = "", operation: @escaping @MainActor () async throws -> Void) -> Bool { false }
    @discardableResult
    func start(operation: @escaping @MainActor () async throws -> Void) -> Bool { false }
}

final class NewMachineSheetPresenter: NewMachineSheetPresenting, @unchecked Sendable {
    static let shared = NewMachineSheetPresenter()
    func present(model: Any? = nil, preferredWindow: Any? = nil) {}
    func startFork(sourceMachineID: Any? = nil, sourceName: Any? = nil, preferredWindow: Any? = nil) -> Bool { false }
    func presentNewMachineFetchingPlan(
        preferredWindow: NSWindow?,
        onReservation: @escaping @MainActor (UUID) -> Void
    ) async -> UUID? {
        nil
    }
}

final class MachineDeleteCoordinator: @unchecked Sendable {
    static let shared = MachineDeleteCoordinator()
    var hiddenMachineIDs: Set<String> { [] }
    func canBegin(_ id: String) -> Bool { true }
    func launchEnded(_ id: String) {}
    func beginCleanup(_ id: String) {}
}

struct RemoteTmuxBrokerRegistry: Sendable {
    init() {}
    static func make(from definition: Any) -> (registry: RemoteTmuxBrokerRegistry, rejected: [String: String]) {
        (RemoteTmuxBrokerRegistry(), [:])
    }
}

final class RemoteTmuxBrokerSnapshot: @unchecked Sendable {
    static let shared = RemoteTmuxBrokerSnapshot()
    func update(registry: Any, rejections: Any) {}
}

@MainActor
final class DeviceWorkspaceCreationCoordinator: Sendable {
    func start(on machine: Any, in manager: Any) -> Bool { false }
}

func makeDeviceWorkspaceCreationCoordinator(operations: Any? = nil, catalog: SurfaceCatalog = .shared) -> DeviceWorkspaceCreationCoordinator? {
    nil
}

@MainActor
final class MobileWorkspaceListObserver: Sendable {
    init(tabManager: Any? = nil, sidebarUnread: Any? = nil, configStore: Any? = nil) {}
    func updateConfigStore(_ configStore: Any? = nil) {}
}

@MainActor
final class CloudFeatureAvailabilityObserver: Sendable {
    init(isEnabled: Any? = nil, didChange: Any? = nil) {}
}

@MainActor
final class CloudTunnelActivationObserver: Sendable {
    init(isStartRefused: Any? = nil, bringDown: Any? = nil) {}
}

@MainActor
final class SurfaceResourceDragRegistry: Sendable {
    static let shared = SurfaceResourceDragRegistry()
    func group(id: UUID) -> SurfaceResourceGroup? { nil }
    func discard(id: UUID) {}
}

@MainActor
final class CloudGuestURLService: Sendable {
    init(machineID: String, executable: URL?, resolveContext: Any? = nil) {}
    func update(link: Any, socketPath: String, terminals: [String]) {}
    func updateTerminals(_ terminals: [String]) {}
    func recoverOnLinkProgress() {}
    func stop() {}
}

@MainActor
final class CloudPortAccessStore: Sendable {
    init() {}
    func remove(machineID: Any) async {}
    func model(machineID: Any, target: Any, scheme: Any? = nil, create: () -> CloudPortAccessModel) -> CloudPortAccessModel {
        create()
    }
    struct Key: Hashable, Sendable {
        var machineID: String = ""
        var port: Int = 0
    }
    var models: [Key: CloudPortAccessModel] { [:] }
}

enum CloudPortRoutePlan {
    case privateDirect(String)
    case unsupported(String)
    static func plan(resource: Any, privateAddress: Any? = nil) -> CloudPortRoutePlan {
        .unsupported("Cloud port forwarding disabled")
    }
    static func blocker(supportsPreviews: Bool, privateAddress: String?, allowLoopback: Bool = false) -> CloudPortDiscoveryState? {
        nil
    }
}

struct CmuxRemoteTmuxConfigDefinition: Codable, Sendable, Equatable {}

@MainActor
final class AgentChatSessionRegistry {
    func liveSessionSnapshot(surfaceID: String) -> AgentChatSessionRecord? { nil }
    nonisolated static func openCodexRolloutPaths(pid: Int) -> [String] { [] }
    nonisolated static func openCodexRolloutPaths(pid: pid_t) -> [String] { [] }
}

struct AgentChatTranscriptResolver: Sendable {
    let codexConfigRoot: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
    func transcriptPath(for record: AgentChatSessionRecord) -> String? { nil }
    func boundedTranscriptPath(for record: AgentChatSessionRecord) -> String? { nil }
}

@MainActor
final class AgentChatTranscriptService {
    struct SidebarRevisionSnapshot: Sendable, Equatable {
        let liveRevision: UInt64 = 0
        let historyRevision: UInt64 = 0
    }

    let registry = AgentChatSessionRegistry()
    let resolver = AgentChatTranscriptResolver()

    var sidebarRevisionSnapshot: SidebarRevisionSnapshot { .init() }

    func sidebarChanges() -> AsyncStream<SidebarRevisionSnapshot> {
        AsyncStream { $0.finish() }
    }

    static func recordResumeIntent(
        sessionID: Any? = nil,
        source: Any? = nil,
        surfaceID: Any? = nil,
        workspaceID: Any? = nil,
        workingDirectory: Any? = nil
    ) {}

    func start() {}
    func shutdown() {}
    func noteHookEvent(_ event: Any) {}
    func noteExplicitInput(surfaceID: String, at: Date) -> Bool { false }
    func sessionRecords(workspaceID: UUID?) -> [AgentChatSessionRecord] { [] }
    func currentOrMostRecentSessionRecord(surfaceID: String) -> AgentChatSessionRecord? { nil }
    func sessionRecord(sessionID: String) -> AgentChatSessionRecord? { nil }
    func activeSessions(workspaceID: UUID) -> [AgentChatSessionRecord] { [] }
    func sessionID(forSurfaceID surfaceID: String) -> String? { nil }
    func debugSessionDump() -> [String: Any] { [:] }
    func observeAgentProcessesForListing(surfaceIDs: [String]?, waitUpTo: Duration) async -> Bool { true }
    func observeAgentProcessesForListing(surfaceIDs: Set<UUID>, waitUpTo: Duration) async -> Bool { true }
    func shouldListEndedSession(_ record: AgentChatSessionRecord) -> Bool { false }
    func updateSessionWorkspace(sessionID: String, workspaceID: String) {}
    func wirePayload(_ descriptor: Any) -> [String: Any]? { nil }
    func history(sessionID: String, beforeSeq: Int?, limit: Int) async -> Any? { nil }
    func refreshSessionBindings(sessionID: String) async -> AgentChatSessionRecord? { nil }
}

protocol CodeRouterHandoffMinting: Sendable {
    func mint(teamID: String) async throws -> CodeRouterHandoffLease
}

struct CodeRouterHandoffLease: Sendable {
    let teamID: String
    let lease: String
    let expiresAt: String
}

struct CodeRouterSocketPeerVerifier: Sendable {
    static let production = CodeRouterSocketPeerVerifier()
    init(validation: (@Sendable (SocketPeerAuditToken) -> Bool)? = nil) {}
    func isTrusted(_ token: SocketPeerAuditToken) -> Bool { false }
}

enum CodeRouterHandoffClientError: Error, Equatable, Sendable, CustomStringConvertible {
    case notSignedIn
    case sessionUnavailable
    case sessionChanged
    case invalidTeam
    case invalidResponse
    case expiredLease
    case redirectedResponse
    case httpStatus(Int)
    case backendUnreachable

    var code: String { "coderouter_handoff_error" }
    var description: String { "CodeRouter handoff error" }
}

actor CodeRouterHandoffClient: CodeRouterHandoffMinting {
    init(auth: Any? = nil) {}
    static func isValidLeaseSyntax(_ lease: String) -> Bool { true }
    func mint(teamID: String) async throws -> CodeRouterHandoffLease {
        throw CodeRouterHandoffClientError.notSignedIn
    }
}

final class CodeRouterHandoffArmGrantStore: Sendable {
    enum ArmResult: Sendable, Equatable {
        case armed, replay, busy
    }

    func armWithResult(
        token: SocketPeerAuditToken,
        processStartTime: SocketPeerProcessStartTime,
        authorizationGeneration: UInt64,
        sessionBinding: Any?,
        capabilityNonce: Data,
        clientChallenge: Data
    ) -> ArmResult { .busy }

    func consume(
        token: SocketPeerAuditToken,
        processStartTime: SocketPeerProcessStartTime,
        authorizationGeneration: UInt64,
        currentSessionBinding: CodeRouterHandoffSessionBinding
    ) -> CodeRouterHandoffSessionBinding? { nil }

    func sessionBindingForBegin(
        token: SocketPeerAuditToken,
        processStartTime: SocketPeerProcessStartTime,
        authorizationGeneration: UInt64,
        currentSessionBinding: CodeRouterHandoffSessionBinding
    ) -> CodeRouterHandoffSessionBinding? { nil }
}

@MainActor
public final class CloudTeamPickerPresentation: ObservableObject {
    @Published public var isPresented: Bool = false
    public init() {}
}

final class MobileHostService: Sendable {
    static let shared = MobileHostService()
    static let irohReleaseGateRPCMethods: [String] = []
    static let mobileHostCapabilities: [String] = []
    static let taskCreateCapability = "task.create"
    static let workspaceChangesCapability = "workspace.changes"
    static func hasEventSubscribers(topic: String) -> Bool { false }

    var workspaceChangesService: Any? = nil

    func start() {}
    func syncToSettings() {}
    func configure(auth: Any? = nil) {}

    struct LocalSizingUser {
        var id: String? = nil
        var displayName: String? = nil
    }
    struct StatusSnapshot {
        var routes: Any? = nil
        var payload: [String: Any] = [:]
    }

    static func emitEvent(topic: String, payload: [String: Any]) {}
    static func publicStatusPayload(routes: Any? = nil) -> [String: Any] { [:] }
    func currentLocalSizingUser() -> LocalSizingUser? { nil }
    func currentAuthenticatedLocalUserEmail() async -> String? { nil }
    func statusSnapshot() -> StatusSnapshot { .init() }
    func emitClientScopedEvent(topic: String, payload: (Set<String>) -> [String: Any]?) {}
    func clientIDs(forConnectionID connectionID: String) -> Set<String> { [] }
    func clientIDs(forConnectionID connectionID: UUID) -> Set<String> { [] }
    func debugConfigureAcceptedStackAuthTokenForTesting(_ token: Any? = nil) {}
}

struct MobileHostIrohArtifactTransferRegistry {
    enum IssueFailure {
        case fileNotFound, permissionDenied, notRegularFile, readFailed, unavailable
    }
    struct Error: Swift.Error {
        var issueFailure: IssueFailure = .fileNotFound
        static let unavailable = Error(issueFailure: .unavailable)
    }
}

struct ChatArtifactLaneDescriptor: Codable, Sendable {
    var lane: String = ""
}

enum MobileHostRPCEnvelope {
    static func encodeResponse(id: Any?, result: MobileHostRPCResult) -> Data {
        Data()
    }
}

actor MobileHostConnectionRegistry {
    static let shared = MobileHostConnectionRegistry()
    func debugCloseConnections(connectionID: UUID?) -> [UUID] { [] }
}

struct SSHTuiOpenFailure: Error {
    var reason: String = ""
}

struct RemoteTmuxError: Error {
    var message: String = ""
}

struct MobileHostRPCRequest: @unchecked Sendable {
    let id: Any?
    let method: String
    let params: [String: Any]
    let auth: Any? = nil
    var mustNameItsTerminal: Bool { false }
    static func phoneNamedTerminalID(params: [String: Any]) -> UUID? { nil }
}

struct MobileHostRPCError: Error, @unchecked Sendable {
    let code: String
    let message: String
    let data: Any?
}

enum MobileHostRPCResult: @unchecked Sendable {
    case ok(Any)
    case failure(Any)
}

struct MobileHostRPCExecutionContext: Sendable {
    var peerAuditToken: SocketPeerAuditToken? = nil
    var connectionID: UUID? = nil

    func issueArtifactTransfer(canonicalPath: String) async throws -> ChatArtifactLaneDescriptor {
        throw MobileHostIrohArtifactTransferRegistry.Error.unavailable
    }
}

@MainActor
final class MobileHostTerminalInputApplier: Sendable {
    static let shared = MobileHostTerminalInputApplier()
    enum Admission: Equatable {
        case proceed
        case answer(MobileTerminalInputAcknowledgement)
    }
    static func unavailable(_ delivery: MobileTerminalInputDelivery?) -> MobileTerminalInputAcknowledgement? { nil }
    func admit(_ delivery: MobileTerminalInputDelivery?, surfaceID: UUID) -> Admission { .proceed }
    func completeAccepted(_ delivery: MobileTerminalInputDelivery?) -> MobileTerminalInputAcknowledgement? { nil }
    func complete(_ delivery: MobileTerminalInputDelivery?, result: Any? = nil) -> MobileTerminalInputAcknowledgement? { nil }
    func reject(_ delivery: MobileTerminalInputDelivery?) -> MobileTerminalInputAcknowledgement? { nil }
}

enum MobileHostPublicStatusCache {
    enum Result {
        case ok(Any)
    }
    static func result(includeIdentity: Bool) -> Result {
        .ok([String: Any]())
    }
}

enum MobileCompatibleMacTags {
    static func tags() -> [String] { [] }
    static func rejectedTags(from tags: [String]) -> [String] { [] }
    static func set(_ tags: [String]) -> [String] { tags }
}

enum MobileHostIrxRuntime {
    struct JournalStub {
        func record(_ category: String, _ event: String, _ metadata: [String: String]) {}
    }
    static let journal = JournalStub()
    static let pathModeDefaultsKey = "cmux.iroh.pathMode"
    static let shared = MobileHostIrxRuntimeStub()
}

final class MobileHostIrxRuntimeStub: @unchecked Sendable {
    func setIrohDebugTransportVerificationMode(_ mode: Any? = nil) async {}
}

enum PhoneForwardingMode: String, Sendable {
    case onlyWhenAway = "only_when_away"
    case always = "always"
}

struct PhonePushConfiguration: Sendable, Equatable {
    var forwardingEnabled: Bool = false
    var mode: PhoneForwardingMode = .onlyWhenAway
    var hideContent: Bool = false
}

struct PhonePushConfigurationState: Sendable, Equatable {
    var configuration: PhonePushConfiguration = PhonePushConfiguration()
}

struct PhonePushTestAdmission: Sendable {
    var testStageRawValue: String = "disabled"
}

@MainActor
final class PhonePushClient: ObservableObject, @unchecked Sendable {
    static let shared = PhonePushClient()
    static let settingsDidChangeNotification = Notification.Name("PhonePushClientSettingsDidChange")

    @Published var configurationState = PhonePushConfigurationState()

    func forwardDismissed(ids: [String], badgeCount: Int) {}
    func configuration() -> PhonePushConfiguration { configurationState.configuration }
    func forward(_ notification: Any, badgeCount: Int) {}
    func forwardTest(badgeCount: Int) -> PhonePushTestAdmission { PhonePushTestAdmission() }
    func reloadConfigurationFromDefaults() {}
    func updateSettings(
        forwardingEnabled: Bool? = nil,
        mode: PhoneForwardingMode? = nil,
        hideContent: Bool? = nil,
        defaults: UserDefaults = .standard
    ) -> PhonePushConfiguration {
        configurationState.configuration
    }
}

final class MachineCreateCoordinator: @unchecked Sendable {
    static let shared = MachineCreateCoordinator()
    var operations: [MachineCreateOperation] = []
    func cancelOperations(forPresentationWorkspace id: UUID) {}
    func cancelOperations(forPresentationWorkspaces ids: Set<UUID>) {}
    func cancelAllForAuthTransition(cleanupCreatedMachines: Bool = false) {}
    func start(
        _ request: Any? = nil,
        cancellableLaunch: ((Any, [String], @escaping @MainActor (String) -> Void, @escaping (CloudVMActionLauncher.Completion) -> Void) -> CloudVMActionLauncher.CancellationHandle?)? = nil
    ) -> Bool { false }
}

enum MobileHostRequestActivity {
    static func hasRecentActivity(within interval: TimeInterval) -> Bool { false }
    static func quietDelay(for interval: TimeInterval) -> TimeInterval { 0 }
}

struct CloudTreeRemoteWorkspaceMembers: Equatable, Sendable {
    var terminals: [SurfaceResource] = []
    var browsers: [SurfaceResource] = []
    var displays: [SurfaceResource] = []
    var all: [SurfaceResource] { terminals + browsers + displays }
    var ids: [SurfaceResourceID] { all.map(\.id) }
    var isEmpty: Bool { terminals.isEmpty && browsers.isEmpty && displays.isEmpty }
    static let none = CloudTreeRemoteWorkspaceMembers()
}

enum CloudTreeRemoteWorkspaceLookup: Equatable, Sendable {
    case found(SurfaceRemoteWorkspace, CloudTreeRemoteWorkspaceMembers)
    case ambiguous([SurfaceRemoteWorkspace])
    case notFound
}

enum CloudTreeNodeBuilder {
    static func nodeID(workspace: String, machine: SurfaceMachineID) -> String {
        "\(machine.rawValue):\(workspace)"
    }
    static func predictedDefaultWorkspaceName(on machine: SurfaceMachineID, snapshot: SurfaceCatalogSnapshot, pendingCreations: Any? = nil) -> String? {
        "workspace"
    }
    static func lookupRemoteWorkspace(_ selector: String, on machine: SurfaceMachineID, snapshot: SurfaceCatalogSnapshot) -> CloudTreeRemoteWorkspaceLookup {
        .notFound
    }

    static func localWorkspaceShowing(
        remoteWorkspaceID: String,
        placements: [SurfaceResourcePlacement],
        snapshot: SurfaceCatalogSnapshot
    ) -> UUID? {
        nil
    }
}

protocol CloudTerminalNavigationCatalog: AnyObject {
    func localWorkspaceShowing(remoteWorkspaceID: String, placements: [SurfaceResourcePlacement]) -> UUID?
    func projectTerminal(_ resource: SurfaceResourceID, in workspaceID: UUID, view: SurfaceRemoteView?) async throws -> SurfaceProjection
    func terminalWorkspaceLayout(machine: SurfaceMachineID, workspaceID: String) async -> SurfaceProjectionLayout?
    func openTerminalWorkspace(_ group: SurfaceResourceGroup, title: String, layout: SurfaceProjectionLayout?) async throws -> (workspaceID: UUID, projections: [SurfaceProjection])
    func bindTerminalWorkspace(localWorkspaceID: UUID, machine: SurfaceMachineID, remoteWorkspaceID: String, generatedTitle: String)
}

enum CloudTreeNodeActions {
    struct Bound {
        func openWorkspace(_ machine: SurfaceMachineID, _ workspace: SurfaceRemoteWorkspace, _ group: SurfaceResourceGroup) {}
    }
    static func bound(
        navigationHost: Any? = nil,
        catalog: @escaping () -> SurfaceCatalog = { SurfaceCatalog.shared },
        selectedWorkspaceID: @escaping () -> UUID? = { nil },
        selectLocalWorkspace: @escaping (UUID) -> Any? = { _ in nil },
        onDidMutate: @escaping () -> Void = {},
        onFailure: @escaping (Any) -> Void = { _ in },
        refresh: @escaping () -> Void = {},
        workspaceCreationHost: @escaping () -> Any? = { nil },
        recordCloudWorkspaceSelection: @escaping (SurfaceMachineID) -> Void = { _ in }
    ) -> Bound {
        Bound()
    }
    static func localWorkspaceTitle(hostName: String, group: SurfaceResourceGroup) -> String {
        hostName
    }
    static func resolvedMachineName(_ machine: SurfaceMachineID, snapshot: SurfaceCatalogSnapshot) -> String {
        machine.rawValue
    }
    @MainActor
    static func createWorkspaceAndOpenLocally(
        machine: SurfaceMachineID,
        provider: any SurfaceProvider,
        catalog: SurfaceCatalog,
        name: String?,
        focus: Bool,
        openLocally: Bool = true,
        existingWorkspace: SurfaceRemoteWorkspace? = nil,
        existingTerminal: SurfaceResource? = nil,
        existingRemoteView: SurfaceRemoteView? = nil,
        existingReservation: Any? = nil,
        host: Any? = nil,
        resolveExistingWorkspace: Any? = nil,
        validateOperation: @escaping @MainActor () throws -> Void = { try Task.checkCancellation() },
        reuseFailedCreation: Bool = false
    ) async throws -> (
        workspace: SurfaceRemoteWorkspace,
        terminal: SurfaceResource,
        opened: (workspaceID: UUID, projections: [SurfaceProjection])?
    ) {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }

    @MainActor
    static func deleteWorkspaceAndTerminals(
        machine: SurfaceMachineID,
        provider: any SurfaceProvider,
        catalog: SurfaceCatalog,
        workspaceID: String
    ) async throws -> Int {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }
}

struct CloudWorkspaceSidebarPresentation: Sendable {
    var machineLabel: String = ""
    var directoryCandidates: [String] = []
    var isDeviceWorkspace: Bool = false
    var deviceLabel: String? = nil

    static var unavailableDirectory: String { "" }
    static func deviceLabel(workspace: Any, catalog: Any? = nil) -> String? { nil }

    init?(workspace: Any, orderedPanelIDs: [UUID], usesLastSegmentPath: Bool, catalog: Any? = nil) {
        return nil
    }
}

extension Workspace {
    func terminalRunsOnAnotherMachine(_ surfaceID: UUID) -> Bool { false }
}

enum CloudTuiManualMirrorStopReason: Sendable {
    case cloudUnavailable
    case accessLost
    case signedOut
    init(accessLoss: Any? = nil) {
        self = .accessLost
    }
}

@MainActor
final class CloudNotificationSyncHub: @unchecked Sendable {
    static let shared = CloudNotificationSyncHub()
    let persistenceStore = CloudNotificationSyncStore()
    func unregister(machineID: Any) {}
    func admit(_ item: Any, machineID: Any) {}
    func setUnread(_ terminalIDs: Any, machineID: Any) {}
    func register(_ sync: Any) {}
}

struct CloudNotificationLocalDelivery {
    init(machineID: Any? = nil, origin: Any? = nil, store: Any? = nil, admit: Any? = nil, machineName: Any? = nil, terminalTitle: Any? = nil) {}
    func deliver(_ row: Any, to target: Any) -> CloudNotificationDeliveryOutcome {
        .declined
    }
}

extension SurfaceCatalog {
    func removeCloudMachine(_ machineID: SurfaceMachineID) {}
}

struct CloudBrowserAccessView<Content: View>: View {
    let content: Content
    init(panel: Any? = nil, backgroundColor: Any? = nil, isVisibleInUI: Any? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
    }
}

struct MobileBrowserInputReplayer: Sendable {
    func replayPointer(_ input: Any, in webView: Any) throws {}
    func replayKey(_ input: Any, in webView: Any) throws {}
}

extension Workspace {
    var deviceMachineForNewWorkspace: Any? { nil }
    func detachRemoteTmuxMirrorKeptOpenLocallyIfNeeded() {}
}

final class NewMachineModel: @unchecked Sendable {
    enum Outcome: Sendable, Equatable {
        case cancelled
        case provisioned
    }
    enum Mode: Sendable {
        case base(workspaceID: UUID)
    }
    var onFinished: ((Outcome) -> Void)? = nil
    init(mode: Mode? = nil, plan: Any? = nil, memoryOptionsMb: Any? = nil, lockedMemoryOptionsMb: Any? = nil, memoryUpgradePlanId: Any? = nil, memoryUpgradePlansByMb: Any? = nil, submit: ((Any) -> Bool)? = nil) {}
}

final class CloudTreeNSOutlineView: NSOutlineView {
    var onMoveMachine: ((Int) -> Bool)? = nil
}

enum PhoneReplyInjectOutcome: Sendable {
    case delivered
    case retryable
    case permanentlyUndeliverable
}

final class PhoneReplyInboxClient: @unchecked Sendable {
    static let shared = PhoneReplyInboxClient()
    func configure(auth: Any? = nil) {}
}

final class PhoneReplyInboxCoordinator: @unchecked Sendable {
    static let shared = PhoneReplyInboxCoordinator()
    func sweepSoon(reason: String) {}
    func configure(client: Any? = nil) {}
    var injectTerminalInput: ((Any, Bool) -> PhoneReplyInjectOutcome)? = nil
}

final class MacPairedMacBackupPublisher: @unchecked Sendable {
    static let shared = MacPairedMacBackupPublisher()
    func configure(auth: Any? = nil) {}
}

extension TerminalController {
    func attachAuth(coordinator: Any? = nil) {}
}

extension TerminalTheme {
    init(ghosttyConfig config: GhosttyConfig) {
        let monokai = TerminalTheme.monokai
        let palette: [String] = (0...15).map { index in
            config.palette[index]?.hexString() ?? monokai.palette[index]
        }
        let cursorColorSemantic = config.cursorColorSemantic.flatMap {
            TerminalTheme.CellRelativeColor(rawValue: $0.rawValue)
        }
        let cursorTextSemantic = config.cursorTextColorSemantic.flatMap {
            TerminalTheme.CellRelativeColor(rawValue: $0.rawValue)
        }
        let selectionBackgroundSemantic = config.selectionBackgroundSemantic.flatMap {
            TerminalTheme.CellRelativeColor(rawValue: $0.rawValue)
        }
        let selectionForegroundSemantic = config.selectionForegroundSemantic.flatMap {
            TerminalTheme.CellRelativeColor(rawValue: $0.rawValue)
        }
        let cursorText = config.hasParsedCursorTextColor && cursorTextSemantic == nil
            ? config.cursorTextColor.hexString()
            : nil
        self.init(
            background: config.backgroundColor.hexString(),
            foreground: config.foregroundColor.hexString(),
            boldColor: config.boldColor,
            cursor: config.cursorColor.hexString(),
            cursorColorSemantic: cursorColorSemantic,
            cursorText: cursorText,
            cursorTextSemantic: cursorTextSemantic,
            selectionBackground: config.selectionBackground.hexString(),
            selectionBackgroundSemantic: selectionBackgroundSemantic,
            selectionForeground: config.selectionForeground.hexString(),
            selectionForegroundSemantic: selectionForegroundSemantic,
            palette: palette
        )
    }
}
