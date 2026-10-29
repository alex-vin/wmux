import Bonsplit
import Carbon.HIToolbox
import CmuxControlSocket
import CMUXMobileCore
import CmuxPanes
import CmuxRemoteSession
import Foundation
import GhosttyKit

extension RemoteTmuxKeyName {
    init?(inputEvent: ghostty_input_key_s) {
        guard inputEvent.action == GHOSTTY_ACTION_PRESS
                || inputEvent.action == GHOSTTY_ACTION_REPEAT,
              !inputEvent.composing else {
            return nil
        }

        let base: String
        switch Int(inputEvent.keycode) {
        case kVK_Home: base = "Home"
        case kVK_End: base = "End"
        case kVK_Help: base = "IC"
        case kVK_ForwardDelete: base = "DC"
        case kVK_PageUp: base = "PPage"
        case kVK_PageDown: base = "NPage"
        case kVK_UpArrow: base = "Up"
        case kVK_DownArrow: base = "Down"
        case kVK_LeftArrow: base = "Left"
        case kVK_RightArrow: base = "Right"
        case kVK_F1: base = "F1"
        case kVK_F2: base = "F2"
        case kVK_F3: base = "F3"
        case kVK_F4: base = "F4"
        case kVK_F5: base = "F5"
        case kVK_F6: base = "F6"
        case kVK_F7: base = "F7"
        case kVK_F8: base = "F8"
        case kVK_F9: base = "F9"
        case kVK_F10: base = "F10"
        case kVK_F11: base = "F11"
        case kVK_F12: base = "F12"
        default: return nil
        }

        if let textPointer = inputEvent.text {
            let text = String(cString: textPointer)
            if !text.isEmpty {
                guard text.unicodeScalars.count == 1,
                      let scalar = text.unicodeScalars.first,
                      (0xF700...0xF8FF).contains(scalar.value) else {
                    return nil
                }
            }
        }

        let rawModifiers = inputEvent.mods.rawValue
        guard rawModifiers & GHOSTTY_MODS_SUPER.rawValue == 0 else { return nil }
        var modifiers: [String] = []
        modifiers.reserveCapacity(3)
        if rawModifiers & GHOSTTY_MODS_CTRL.rawValue != 0 { modifiers.append("C") }
        if rawModifiers & GHOSTTY_MODS_ALT.rawValue != 0 { modifiers.append("M") }
        if rawModifiers & GHOSTTY_MODS_SHIFT.rawValue != 0 { modifiers.append("S") }
        self.init(rawName: (modifiers + [base]).joined(separator: "-"))
    }
}

/// Resolves a live surface to the stable workspace panel that owns its layout.
///
/// Ordinary surfaces use the same identity for both fields. A projected remote
/// tmux pane keeps its live terminal identity in ``surfaceID`` while mutations
/// that belong to the workspace layout use ``containerPanelID``.
@MainActor
struct WorkspaceSurfaceOwnershipTarget {
    let surfaceID: UUID
    let containerPanelID: UUID
    let panel: any Panel
}

extension Workspace {
    var isRemoteTmuxMirror: Bool { false }

    struct RemoteTmuxSessionMirrorStub {
        func controlPaneLocations() -> [RemoteTmuxControlPaneLocation] { [] }
    }
    var remoteTmuxSessionMirror: RemoteTmuxSessionMirrorStub? { nil }

    func controlReorderContainerPanelID(for surfaceID: UUID) -> UUID? {
        panels[surfaceID] == nil ? nil : surfaceID
    }

    func canResolveTerminalPathsAgainstLocalFilesystem(surfaceID: UUID) -> Bool {
        if let machine = machineOwningSurface(surfaceID) { return machine.isLocal }
        return !isRemoteTerminalSurface(surfaceID)
    }

    func isRemoteTerminalContext(_ surfaceOrPanelID: UUID) -> Bool {
        let surfaceID = surfaceOwnershipTarget(for: surfaceOrPanelID)?.surfaceID
            ?? surfaceOrPanelID
        return isRemoteTerminalSurface(surfaceID)
    }

    @discardableResult
    func performRemoteTmuxMirrorMutation<Result>(
        _ operation: () throws -> Result
    ) rethrows -> Result {
        try operation()
    }

    nonisolated static func bonsplitSplitButtonBackdropEffect(
        defaults: UserDefaults = .standard
    ) -> BonsplitConfiguration.Appearance.SplitButtonBackdropEffect {
        .init(
            style: .translucentChrome,
            fadeWidth: 16,
            contentFadeWidth: 24,
            solidWidth: 23.875,
            solidSurfaceWidthAdjustment: 0,
            separatorFadeWidth: 8,
            fadeRampStartFraction: 0.60,
            leadingOpacity: 0,
            trailingOpacity: 0.8625,
            contentOcclusionFraction: 0.6875,
            masksTabContent: true
        )
    }

    func surfaceOwnershipTarget(
        for surfaceOrPanelID: UUID
    ) -> WorkspaceSurfaceOwnershipTarget? {
        if let panel = panels[surfaceOrPanelID],
           surfaceIdFromPanelId(surfaceOrPanelID) != nil {
            return WorkspaceSurfaceOwnershipTarget(
                surfaceID: surfaceOrPanelID,
                containerPanelID: surfaceOrPanelID,
                panel: panel
            )
        }
        guard let panelID = panelIdFromSurfaceId(TabID(uuid: surfaceOrPanelID)),
              let panel = panels[panelID] else { return nil }
        return WorkspaceSurfaceOwnershipTarget(
            surfaceID: surfaceOrPanelID,
            containerPanelID: panelID,
            panel: panel
        )
    }

    func terminalInputTarget(
        forPanelID panelID: UUID
    ) -> (surfaceID: UUID, panel: TerminalPanel)? {
        guard let panel = panels[panelID] as? TerminalPanel else { return nil }
        return (panel.id, panel)
    }

    func focusedTerminalInputTarget() -> (surfaceID: UUID, panel: TerminalPanel)? {
        guard let focusedPanelId else { return nil }
        return terminalInputTarget(forPanelID: focusedPanelId)
    }

    typealias ControlSurfaceProjection = (surfaceID: UUID, paneID: UUID?, panel: any Panel)

    func controlSurfaceTarget(for surfaceID: UUID) -> ControlSurfaceProjection? {
        if let panel = panels[surfaceID] {
            return (surfaceID, paneId(forPanelId: surfaceID)?.id, panel)
        }
        guard let dock = _dockSplit,
              let panel = dock.panels[surfaceID] else {
            return nil
        }
        return (surfaceID, dock.paneId(forPanelId: surfaceID)?.id, panel)
    }

    func controlTerminalTarget(for surfaceID: UUID) -> (surfaceID: UUID, panel: TerminalPanel)? {
        guard let target = controlSurfaceTarget(for: surfaceID),
              let panel = target.panel as? TerminalPanel else { return nil }
        return (target.surfaceID, panel)
    }

    func controlTerminalPanel(for surfaceID: UUID) -> TerminalPanel? {
        controlTerminalTarget(for: surfaceID)?.panel
    }

    func controlSurfaceProjection(
        forContainerPanelID containerPanelID: UUID
    ) -> ControlSurfaceProjection? {
        guard let panel = panels[containerPanelID] else { return nil }
        return (containerPanelID, paneId(forPanelId: containerPanelID)?.id, panel)
    }

    func terminalPanels(projectedFromPanelID panelID: UUID) -> [TerminalPanel] {
        if let panel = panels[panelID] as? TerminalPanel {
            return [panel]
        }
        return []
    }

    @discardableResult
    func reorderSurface(panelId: UUID, toIndex index: Int, focus: Bool = true) -> Bool {
        guard let tabId = surfaceIdFromPanelId(panelId) else { return false }
        guard bonsplitController.reorderTab(tabId, toIndex: index) else { return false }
        if focus, let paneId = paneId(forPanelId: panelId) {
            applyTabSelection(tabId: tabId, inPane: paneId)
        } else {
            scheduleFocusReconcile()
        }
        scheduleTerminalGeometryReconcile()
        return true
    }

    func remoteTmuxControlPane(paneID: UUID) -> RemoteTmuxControlPaneLocation? { nil }
    func remoteTmuxControlPane(surfaceID: UUID) -> RemoteTmuxControlPaneLocation? { nil }
    func remoteTmuxControlPane(surfaceID: String) -> RemoteTmuxControlPaneLocation? { nil }

    func forkProjectedTmuxAgentConversation(
        _ projectedPane: RemoteTmuxControlPaneLocation,
        snapshot: SessionRestorableAgentSnapshot,
        destination: AgentConversationForkDestination
    ) -> Bool {
        false
    }

    enum RemoteTmuxControlSurfaceTarget {
        case notRemote
        case unresolvedMirror
        case pane(RemoteTmuxControlPaneLocation)
    }

    func remoteTmuxControlSurfaceTarget(surfaceID: UUID) -> RemoteTmuxControlSurfaceTarget { .notRemote }

    func controlDefaultTerminalTarget(
        paneID requestedPaneID: UUID?
    ) -> (surfaceID: UUID, panel: TerminalPanel)? {
        if let requestedPaneID {
            if let paneID = bonsplitController.allPaneIds.first(where: { $0.id == requestedPaneID }),
               let tab = bonsplitController.selectedTab(inPane: paneID),
               let panelID = panelIdFromSurfaceId(tab.id),
               let panel = terminalPanel(for: panelID) {
                return (panelID, panel)
            }
            return nil
        }
        return focusedTerminalInputTarget()
    }

    func isFocusedTerminalInputSurface(_ surfaceID: UUID) -> Bool {
        focusedTerminalInputTarget()?.surfaceID == surfaceID
    }

    func controlTabTarget(for surfaceID: UUID) -> (panelID: UUID, paneID: UUID?)? {
        guard panels[surfaceID] != nil else { return nil }
        return (surfaceID, paneId(forPanelId: surfaceID)?.id)
    }

    func controlRequestedSurfaceTarget(
        explicitSurfaceID: UUID?,
        routedPaneID: UUID?
    ) -> (requestedSurfaceID: UUID, target: ControlSurfaceProjection?)? {
        if let explicitSurfaceID {
            return (explicitSurfaceID, controlSurfaceTarget(for: explicitSurfaceID))
        }
        if let routedPaneID {
            guard let paneID = bonsplitController.allPaneIds.first(where: {
                $0.id == routedPaneID
            }),
            let selectedTab = bonsplitController.selectedTab(inPane: paneID),
            let panelID = panelIdFromSurfaceId(selectedTab.id) else {
                return nil
            }
            return (panelID, controlSurfaceTarget(for: panelID))
        }
        guard let focusedPanelId else { return nil }
        return (focusedPanelId, controlSurfaceProjection(forContainerPanelID: focusedPanelId))
    }
}

@MainActor
extension TerminalController {
    nonisolated static let mobileReplayScrollbackLineBudget = 240

    func controlTabManager(surfaceID: UUID) -> TabManager? {
        AppDelegate.shared?.locateSurface(surfaceId: surfaceID)?.tabManager
            ?? locateDockSurface(surfaceID)?.tabManager
    }

    func controlTabManager(paneID: UUID) -> TabManager? {
        v2LocatePane(paneID)?.tabManager
            ?? locateDockPane(paneID)?.tabManager
    }

    func mobileTerminalRenderGridFrame(
        terminalTarget: Any,
        surfaceID: UUID,
        seq: UInt64,
        scrollbackLines: Int = 240,
        anchor: MobileTerminalRenderGridFrame.Anchor = .viewport
    ) -> MobileTerminalRenderGridFrame? { nil }

    func v2MobileSyncFetch(params: [String: Any]) -> V2CallResult {
        .ok([String: Any]())
    }

    func mobileTerminalScrollResponsePayload(
        workspaceID: UUID,
        terminalTarget: Any,
        surfaceID: UUID,
        params: [String: Any]
    ) -> [String: Any] { [:] }

    func v2RefreshRemoteTmuxAwarePaneAndSurfaceRefs(workspace: Workspace) {
        for paneID in workspace.bonsplitController.allPaneIds {
            let panelIDs = workspace.bonsplitController.tabs(inPane: paneID).compactMap {
                workspace.panelIdFromSurfaceId($0.id)
            }
            for panelID in panelIDs {
                _ = v2Ref(kind: .surface, uuid: panelID)
            }
            if !panelIDs.isEmpty {
                _ = v2Ref(kind: .pane, uuid: paneID.id)
            }
        }
    }

    func controlGridSize(panel: any Panel) -> ControlPaneGridSize? {
        guard let panel = panel as? TerminalPanel,
              panel.surface.hasLiveSurface,
              let surface = panel.surface.surface else { return nil }
        let size = ghostty_surface_size(surface)
        guard size.columns > 0, size.rows > 0 else { return nil }
        let cellPoints = panel.surface.cellSizePoints()
        return ControlPaneGridSize(
            columns: Int(size.columns),
            rows: Int(size.rows),
            cellWidthPx: Int(size.cell_width_px),
            cellHeightPx: Int(size.cell_height_px),
            cellWidthPoints: cellPoints.map { Double($0.width) },
            cellHeightPoints: cellPoints.map { Double($0.height) }
        )
    }

    func controlSurfaceSummaries(workspace: Workspace) -> [ControlSurfaceSummary] {
        var paneByPanelID: [UUID: UUID] = [:]
        var indexInPaneByPanelID: [UUID: Int] = [:]
        var selectedInPaneByPanelID: [UUID: Bool] = [:]
        for paneID in workspace.bonsplitController.allPaneIds {
            let tabs = workspace.bonsplitController.tabs(inPane: paneID)
            let selected = workspace.bonsplitController.selectedTab(inPane: paneID)
            for (index, tab) in tabs.enumerated() {
                guard let panelID = workspace.panelIdFromSurfaceId(tab.id) else { continue }
                paneByPanelID[panelID] = paneID.id
                indexInPaneByPanelID[panelID] = index
                selectedInPaneByPanelID[panelID] = tab.id == selected?.id
            }
        }

        return orderedPanels(in: workspace).map { panel in
            let terminalPanel = panel as? TerminalPanel
            let simulatorPanel = panel as? SimulatorPanel
            return ControlSurfaceSummary(
                surfaceID: panel.id,
                typeRawValue: panel.panelType.rawValue,
                title: workspace.panelTitle(panelId: panel.id) ?? panel.displayTitle,
                isFocused: panel.id == workspace.focusedPanelId,
                paneID: paneByPanelID[panel.id],
                indexInPane: indexInPaneByPanelID[panel.id],
                selectedInPane: selectedInPaneByPanelID[panel.id],
                developerToolsVisible: (panel as? BrowserPanel)?.isDeveloperToolsVisible(),
                requestedWorkingDirectory: terminalPanel.flatMap {
                    v2NonEmptyString($0.requestedWorkingDirectory)
                },
                initialCommand: terminalPanel.flatMap {
                    v2NonEmptyString($0.surface.debugInitialCommand())
                },
                tmuxStartCommand: terminalPanel.flatMap {
                    v2NonEmptyString($0.surface.debugTmuxStartCommand())
                },
                isTerminal: terminalPanel != nil,
                resumeBinding: terminalPanel != nil
                    ? controlResumeBinding(from: workspace.surfaceResumeBinding(panelId: panel.id))
                    : nil,
                renderHealthRawValue: terminalPanel?.surface.renderHealth.rawValue,
                simulatorDeviceID: simulatorPanel?.selectedDeviceID,
                simulatorRuntimeIdentifier: simulatorPanel?.selectedRuntimeIdentifier,
                simulatorDeviceTypeIdentifier: simulatorPanel?.selectedDeviceTypeIdentifier,
                simulatorDeviceName: simulatorPanel?.selectedDeviceName,
                simulatorDeviceState: simulatorPanel?.selectedDeviceState
            )
        }
    }

    func controlPaneSummaries(
        workspace: Workspace,
        snapshot: LayoutSnapshot
    ) -> [ControlPaneSummary] {
        let focusedPaneId = workspace.bonsplitController.focusedPaneId
        let geometryByPaneId = Dictionary(
            snapshot.panes.map { ($0.paneId, $0.frame) },
            uniquingKeysWith: { first, _ in first }
        )
        return workspace.bonsplitController.allPaneIds.compactMap { paneID -> ControlPaneSummary? in
            let tabs = workspace.bonsplitController.tabs(inPane: paneID)
            let panelIDs = tabs.compactMap { workspace.panelIdFromSurfaceId($0.id) }
            let selectedTab = workspace.bonsplitController.selectedTab(inPane: paneID)
            let selectedPanelID = selectedTab.flatMap { workspace.panelIdFromSurfaceId($0.id) }
            let frame = geometryByPaneId[paneID.id.uuidString].map {
                ControlPanePixelFrame(x: $0.x, y: $0.y, width: $0.width, height: $0.height)
            }
            guard !panelIDs.isEmpty else { return nil }
            let selectedPanel = selectedTab.flatMap { workspace.panel(for: $0.id) }
            return ControlPaneSummary(
                paneID: paneID.id,
                isFocused: paneID == focusedPaneId,
                surfaceIDs: panelIDs,
                selectedSurfaceID: selectedPanelID,
                pixelFrame: frame,
                gridSize: selectedPanel.flatMap { controlGridSize(panel: $0) }
            )
        }
    }

    func controlSurfacePanels(workspace: Workspace) -> [any Panel] {
        orderedPanels(in: workspace)
    }

    func remoteTmuxMirrorContainerID(in params: [String: JSONValue]) -> UUID? { nil }

    func controlRemoteTmuxSendText(
        workspace: Workspace,
        tabManager: TabManager,
        surfaceID: UUID,
        text: String
    ) -> ControlSurfaceSendResolution? { nil }

    func controlRemoteTmuxSendKey(
        workspace: Workspace,
        tabManager: TabManager,
        surfaceID: UUID,
        key: String
    ) -> ControlSurfaceSendResolution? { nil }

    func controlRemoteTmuxSurfaceSplit(
        workspace: Workspace,
        tabManager: TabManager,
        inputs: ControlSurfaceSplitInputs,
        direction: SplitDirection,
        panelType: PanelType,
        routedPaneID: UUID?
    ) -> ControlSurfaceSplitResolution? { nil }

    func mirrorRoutedUnsupportedOptions(
        insertFirst: Bool = false,
        workingDirectory: String? = nil,
        initialCommand: String? = nil,
        initialInput: String? = nil,
        tmuxStartCommand: String? = nil,
        startupEnvironment: [String: String] = [:],
        initialDividerPosition: Double? = nil,
        remotePTYSessionID: String? = nil
    ) -> [String] { [] }

    func controlRemoteTmuxSurfaceRespawn(
        workspace: Workspace,
        tabManager: TabManager,
        inputs: ControlSurfaceRespawnInputs,
        routedPaneID: UUID?
    ) -> ControlSurfaceRespawnResolution? { nil }

    func controlRemoteTmuxSurfaceCreate(
        workspace: Workspace,
        tabManager: TabManager,
        inputs: ControlSurfaceCreateInputs,
        panelType: PanelType
    ) -> ControlSurfaceCreateResolution? { nil }

    func controlRemoteTmuxSurfaceClose(
        workspace: Workspace,
        tabManager: TabManager,
        surfaceID: UUID,
        isImplicitTarget: Bool,
        routedPaneID: UUID?,
        force: Bool
    ) -> ControlSurfaceCloseResolution? { nil }

    func focusRemoteTmuxControlPane(
        _ location: RemoteTmuxControlPaneLocation,
        workspace: Workspace,
        tabManager: TabManager
    ) -> Bool { false }

    func controlSurfaceReorder(
        surfaceID: UUID,
        inputs: ControlSurfaceReorderInputs,
        requestedFocus: Bool
    ) -> ControlSurfaceReorderResolution {
        let focus = v2FocusAllowed(requested: requestedFocus)
        guard let tabManager = controlTabManager(surfaceID: surfaceID),
              let ws = tabManager.tabs.first(where: {
                  $0.controlReorderContainerPanelID(for: surfaceID) != nil
              }),
              let sourcePanelID = ws.controlReorderContainerPanelID(for: surfaceID),
              let sourcePane = ws.paneId(forPanelId: sourcePanelID),
              let windowID = v2ResolveWindowId(tabManager: tabManager) else {
            return .surfaceNotFound(surfaceID)
        }

        let targetIndex: Int
        if let index = inputs.index {
            guard let currentIndex = ws.indexInPane(forPanelId: sourcePanelID) else { return .reorderFailed }
            targetIndex = index > currentIndex ? index + 1 : index
        } else if let beforeSurfaceID = inputs.beforeSurfaceID {
            guard let anchorPanelID = ws.controlReorderContainerPanelID(for: beforeSurfaceID),
                  let anchorPane = ws.paneId(forPanelId: anchorPanelID),
                  anchorPane == sourcePane,
                  let anchorIndex = ws.indexInPane(forPanelId: anchorPanelID) else {
                return .anchorNotInSamePane
            }
            targetIndex = anchorIndex
        } else if let afterSurfaceID = inputs.afterSurfaceID {
            guard let anchorPanelID = ws.controlReorderContainerPanelID(for: afterSurfaceID),
                  let anchorPane = ws.paneId(forPanelId: anchorPanelID),
                  anchorPane == sourcePane,
                  let anchorIndex = ws.indexInPane(forPanelId: anchorPanelID) else {
                return .anchorNotInSamePane
            }
            targetIndex = anchorIndex + 1
        } else {
            return .reorderFailed
        }

        guard ws.reorderSurface(panelId: sourcePanelID, toIndex: targetIndex, focus: focus) else {
            return .reorderFailed
        }
        return .reordered(
            windowID: windowID,
            workspaceID: ws.id,
            paneID: sourcePane.id,
            surfaceID: surfaceID
        )
    }

    func controlPaneFocus(
        workspace: Workspace,
        paneID requestedPaneID: UUID,
        tabManager: TabManager
    ) -> ControlPaneFocusResolution {
        guard let paneID = workspace.bonsplitController.allPaneIds.first(where: {
            $0.id == requestedPaneID
        }) else {
            return .paneNotFound(requestedPaneID)
        }
        if let windowID = v2ResolveWindowId(tabManager: tabManager) {
            _ = AppDelegate.shared?.focusMainWindow(windowId: windowID)
            setActiveTabManager(tabManager)
        }
        if tabManager.selectedTabId != workspace.id {
            tabManager.selectWorkspace(workspace)
        }
        workspace.bonsplitController.focusPane(paneID)
        return .focused(
            windowID: v2ResolveWindowId(tabManager: tabManager),
            workspaceID: workspace.id,
            paneID: requestedPaneID
        )
    }

    func controlPaneSurfaces(
        workspace: Workspace,
        paneID requestedPaneID: UUID?,
        tabManager: TabManager
    ) -> ControlPaneSurfacesSnapshot? {
        guard let paneID = requestedPaneID.flatMap({ id in
            workspace.bonsplitController.allPaneIds.first(where: { $0.id == id })
        }) ?? workspace.bonsplitController.focusedPaneId else {
            return nil
        }
        let tabs = workspace.bonsplitController.tabs(inPane: paneID)
        let selectedTab = workspace.bonsplitController.selectedTab(inPane: paneID)
        let summaries: [ControlPaneSurfaceSummary] = tabs.compactMap { tab -> ControlPaneSurfaceSummary? in
            guard let panelID = workspace.panelIdFromSurfaceId(tab.id) else { return nil }
            let panel = workspace.panel(for: tab.id)
            return ControlPaneSurfaceSummary(
                surfaceID: panelID,
                title: workspace.panelTitle(panelId: panelID) ?? panel?.displayTitle ?? "",
                typeRawValue: panel?.panelType.rawValue ?? PanelType.terminal.rawValue,
                isSelected: tab.id == selectedTab?.id
            )
        }
        return ControlPaneSurfacesSnapshot(
            workspaceID: workspace.id,
            paneID: paneID.id,
            windowID: v2ResolveWindowId(tabManager: tabManager),
            surfaces: summaries
        )
    }

    func remoteTmuxSplitFocusIntent(requested: Bool) -> RemoteTmuxSplitFocusIntent {
        requested ? .focusCreatedPane : .preserveActivePane
    }

    func controlRemoteTmuxPaneResize(
        workspace: Workspace,
        tabManager: TabManager,
        inputs: ControlPaneResizeInputs
    ) -> ControlPaneResizeResolution? { nil }

    func locateRemoteTmuxControlPane(_ paneID: UUID) -> Any? { nil }
    func locateRemoteTmuxMirrorContainer(_ surfaceID: UUID) -> Any? { nil }
    func remoteTmuxSizingSettlementPayload() -> [String: Any] { [:] }
}

enum RemoteTmuxSplitFocusIntent: Sendable, Equatable {
    case focusCreatedPane
    case preserveActivePane
}

enum RemoteTmuxControlKeySendResult {
    case sent
    case rejected
    case unknownKey
}

struct RemoteTmuxControlPaneLocation: Sendable, Equatable {
    struct Owner: Sendable, Equatable {
        func requestSplit(
            fromPane: Int,
            vertical: Bool,
            focusIntent: RemoteTmuxSplitFocusIntent,
            insertBefore: Bool = false,
            shellCommand: String? = nil,
            workingDirectory: String? = nil
        ) -> Bool { false }
    }
    struct Pane: Sendable, Equatable {
        struct PanelStub: Sendable, Equatable {
            var id: UUID = UUID()
            var panelType: PanelType = .terminal
        }
        var panel: PanelStub = PanelStub()
        var paneID: PaneID = PaneID(id: UUID())
        var title: String = ""
        var isFocused: Bool = false
        var tmuxPaneID: Int = 0
    }
    var containerPanelID: UUID = UUID()
    var owner: Owner = Owner()
    var pane: Pane = Pane()

    func controlFocus(completion: @escaping (Bool) -> Void = { _ in }) -> Bool { false }
    func sendInput(_ text: String) -> Bool { false }
    func sendKey(_ name: String) -> RemoteTmuxControlKeySendResult { .rejected }
    func requestSplit(vertical: Bool, focusIntent: Any? = nil) -> Bool { false }
    func requestRespawn(command: String, workingDirectory: String?) -> Bool { false }
    func requestKill() -> Bool { false }
}
