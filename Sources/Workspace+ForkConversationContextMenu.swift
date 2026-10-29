import CmuxCloud
import Bonsplit
import CmuxCore
import CmuxSettings
import CmuxSurfaceCatalogModel
import Foundation

extension Workspace {
    /// Native SSH forks share provider creation and retry identity with ordinary splits.
    func forkNativeSSHAgentConversation(
        fromPanelId panelID: UUID,
        snapshot: SessionRestorableAgentSnapshot,
        destination: SurfaceDestination
    ) -> TerminalPanel? {
        guard let source = cloudTerminalSourcePlacement(forPanel: panelID), source.machine.isSSH,
              let configuration = remoteConfiguration,
              SSHTuiConnection(configuration: configuration).id == source.machine.rawValue,
              let command = snapshot.retargetingForkWorkingDirectory(
                forkAgentWorkingDirectory(fromPanelId: panelID, snapshot: snapshot)
              ).forkCommand else { return nil }
        return routeCloudPaneTerminalCreate(
            source: source, sourcePanelID: panelID, destination: destination, focus: true,
            commandOverride: SSHTuiConnection(configuration: configuration).commandArguments(command)
        ).panel
    }

    /// A new workspace carries only a remote command; its local scaffold never runs the agent.
    func nativeSSHAgentForkWorkspaceLaunch(
        fromPanelId panelID: UUID,
        snapshot: SessionRestorableAgentSnapshot
    ) -> AgentConversationForkWorkspaceLaunch? {
        guard let configuration = remoteConfiguration,
              machineOwningSurface(panelID)?.rawValue == SSHTuiConnection(configuration: configuration).id,
              var descriptor = configuration.sessionSnapshot() else { return nil }
        let workingDirectory = forkAgentWorkingDirectory(fromPanelId: panelID, snapshot: snapshot)
        guard let command = snapshot.retargetingForkWorkingDirectory(workingDirectory).forkCommand else { return nil }
        descriptor.terminalProfile = .shell
        descriptor.configuredRemoteCommand = command
        guard let forkConfiguration = descriptor.tuiSSHConfiguration(agentSocketPath: configuration.agentSocketPath) else { return nil }
        return AgentConversationForkWorkspaceLaunch(
            workingDirectory: workingDirectory, terminalWorkingDirectory: nil,
            initialTerminalCommand: nil, initialTerminalInput: "", initialTerminalEnvironment: [:],
            remoteConfiguration: forkConfiguration, autoConnectRemoteConfiguration: true,
            startupRestoreAgent: nil
        )
    }

    @discardableResult
    func forkAgentConversationFromContextMenu(
        fromPanelId panelId: UUID,
        destination: AgentConversationForkDestination
    ) async -> Bool {
        guard beginForkAgentConversationAction(panelId: panelId) else {
            return false
        }
        defer {
            endForkAgentConversationAction(panelId: panelId)
        }

        var selection = forkAgentConversationContextMenuOpenSelection(
            forPanelId: panelId
        )
        guard var snapshot = selection.snapshot,
              var ownership = surfaceOwnershipTarget(for: panelId),
              var anchorTabId = surfaceIdFromPanelId(ownership.containerPanelID),
              var paneId = paneId(forPanelId: ownership.containerPanelID) else {
            return false
        }
        let isRemoteContext = isRemoteTerminalContext(ownership.surfaceID)
        guard let authoritativeSnapshot = await authoritativeForkSnapshot(
            selected: snapshot,
            panelId: panelId,
            isRemoteContext: isRemoteContext
        ) else {
            return false
        }
        snapshot = authoritativeSnapshot
        guard let refreshedOwnership = surfaceOwnershipTarget(for: panelId),
              let refreshedAnchorTabId = surfaceIdFromPanelId(
                  refreshedOwnership.containerPanelID
              ),
              let refreshedPaneId = self.paneId(
                  forPanelId: refreshedOwnership.containerPanelID
              ),
              isRemoteTerminalContext(refreshedOwnership.surfaceID)
                  == isRemoteContext else {
            return false
        }
        ownership = refreshedOwnership
        anchorTabId = refreshedAnchorTabId
        paneId = refreshedPaneId
        if AgentForkSupport.requiresForkValidationExecutableIdentity(
            snapshot: snapshot,
            isRemoteContext: isRemoteContext
        ) {
            let selectedSnapshotFingerprint = ContentView.commandPaletteForkSnapshotFingerprint(
                snapshot,
                isRemoteTerminal: isRemoteContext
            )
            let selectedValidationIdentity = AgentForkSupport.forkValidationIdentity(
                snapshot: snapshot,
                isRemoteContext: isRemoteContext
            )
            guard let cachedExecutableFingerprint = SharedLiveAgentIndex.shared.forkSupportProbeExecutableFingerprint(
                workspaceId: id,
                panelId: panelId,
                isRemoteContext: isRemoteContext,
                fallbackSnapshot: snapshot
            ) else {
                return false
            }
            let currentExecutableFingerprint = await SharedLiveAgentIndex.shared.forkValidationExecutableFingerprint(
                snapshot: snapshot,
                isRemoteContext: isRemoteContext
            )
            let refreshedSelection = forkAgentConversationContextMenuOpenSelection(
                forPanelId: panelId
            )
            guard refreshedSelection.availability.isAvailable,
                  let refreshedSnapshot = refreshedSelection.snapshot,
                  ContentView.commandPaletteForkSnapshotFingerprint(
                    refreshedSnapshot,
                    isRemoteTerminal: isRemoteContext
                  ) == selectedSnapshotFingerprint,
                  AgentForkSupport.forkValidationIdentity(
                    snapshot: refreshedSnapshot,
                    isRemoteContext: isRemoteContext
                  ) == selectedValidationIdentity,
                  let refreshedOwnership = surfaceOwnershipTarget(for: panelId),
                  isRemoteTerminalContext(refreshedOwnership.surfaceID)
                    == isRemoteContext,
                  let refreshedAnchorTabId = surfaceIdFromPanelId(
                    refreshedOwnership.containerPanelID
                  ),
                  let refreshedPaneId = self.paneId(
                    forPanelId: refreshedOwnership.containerPanelID
                  ) else {
                return false
            }
            selection = refreshedSelection
            snapshot = refreshedSnapshot
            ownership = refreshedOwnership
            anchorTabId = refreshedAnchorTabId
            paneId = refreshedPaneId
            guard currentExecutableFingerprint == cachedExecutableFingerprint,
                  SharedLiveAgentIndex.shared.forkSupportProbeAccepted(
                    workspaceId: id,
                    panelId: panelId,
                    isRemoteContext: isRemoteContext,
                    fallbackSnapshot: selection.validationFallbackSnapshot
                  ) else {
                return false
            }
        }

        return forkAgentConversation(
            mutationPanelId: ownership.containerPanelID,
            snapshot: snapshot,
            destination: destination,
            anchorTabId: anchorTabId,
            paneId: paneId
        )
    }

    private func forkAgentConversation(
        mutationPanelId: UUID,
        snapshot: SessionRestorableAgentSnapshot,
        destination: AgentConversationForkDestination,
        anchorTabId: TabID,
        paneId: PaneID
    ) -> Bool {
        if let direction = destination.splitDirection {
            return forkAgentConversation(
                fromPanelId: mutationPanelId,
                snapshot: snapshot,
                direction: direction
            ) != nil
        }

        switch destination {
        case .newTab:
            return forkAgentConversationToNewTab(
                fromPanelId: mutationPanelId,
                snapshot: snapshot,
                anchorTabId: anchorTabId,
                paneId: paneId
            ) != nil
        case .newWorkspace:
            return forkAgentConversationToNewWorkspace(
                fromPanelId: mutationPanelId,
                snapshot: snapshot
            )
        case .right, .left, .top, .bottom:
            return false
        }
    }

    private func forkAgentConversationToNewWorkspace(
        fromPanelId panelId: UUID,
        snapshot: SessionRestorableAgentSnapshot
    ) -> Bool {
        guard let owningTabManager,
              let launch = forkAgentWorkspaceLaunch(
                  fromPanelId: panelId,
                  snapshot: snapshot
              ) else {
            return false
        }

        guard let forkWorkspace = owningTabManager.addWorkspaceIfActive(
            workingDirectory: launch.terminalWorkingDirectory,
            initialTerminalCommand: launch.initialTerminalCommand,
            initialTerminalInput: launch.initialTerminalInput,
            initialTerminalStartupRestoreAgent: launch.startupRestoreAgent,
            initialTerminalEnvironment: launch.initialTerminalEnvironment,
            inheritWorkingDirectory: launch.terminalWorkingDirectory != nil,
            autoWelcomeIfNeeded: false
        ) else {
            return false
        }
        if let remoteConfiguration = launch.remoteConfiguration {
            forkWorkspace.configureRemoteConnection(
                remoteConfiguration,
                autoConnect: launch.autoConnectRemoteConfiguration
            )
        }
        if let workingDirectory = launch.workingDirectory,
           launch.terminalWorkingDirectory == nil,
           let forkPanelId = forkWorkspace.focusedPanelId {
            forkWorkspace.updatePanelDirectory(panelId: forkPanelId, directory: workingDirectory)
        }
        return true
    }
}
