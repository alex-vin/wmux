import Foundation
import Testing
import WmuxSettingsUI
import WmuxSidebarProviderKit
import WmuxSettings
import WmuxSwiftRenderUI

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// Regression coverage for the right-click sidebar-button view switcher.
///
/// v0.64.10 shipped seven built-in sidebar views — Default Workspaces plus the
/// Project Worktrees, Attention Queue, Dev Servers, Last Prompt, Super Compact,
/// and Browser Stack presets — that the sidebar-button context menu let users
/// switch between. #4994 ("Replace sidebar extension kit contract") swept that
/// menu behind the experimental Extensions beta flag and stubbed the built-in
/// providers out, so on a default install (beta off) the menu and every one of
/// its views disappeared (https://github.com/manaflow-ai/cmux/issues/5173).
///
/// These tests pin the two guarantees the regression broke: the built-in views
/// are available regardless of the experimental flag, and a selected view
/// resolves to itself (which is what drives the menu's active-view checkmark).
@MainActor
@Suite(.serialized)
struct SidebarProviderMenuRegressionTests {
    /// Stable ids of the built-in sidebar views, in menu order.
    private static let builtInViewIDs: [String] = [
        "cmux.sidebar.default",
        "com.example.cmux.sidebar.project-worktrees",
        "com.example.cmux.sidebar.attention-queue",
        "com.example.cmux.sidebar.dev-servers",
        "com.example.cmux.sidebar.last-prompt",
        "com.example.cmux.sidebar.super-compact",
        "com.example.cmux.sidebar.browser-stack",
    ]

    private static let extensionsBetaKey = "extensions.beta.enabled"
    private static let conversationBetaKey = "sidebar.beta.conversations.enabled"

    private func withExtensionsBeta(_ enabled: Bool, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: Self.extensionsBetaKey)
        defaults.set(enabled, forKey: Self.extensionsBetaKey)
        defer { restore(previous, forKey: Self.extensionsBetaKey) }
        body()
    }

    private func withConversationBeta(_ enabled: Bool, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: Self.conversationBetaKey)
        defaults.set(enabled, forKey: Self.conversationBetaKey)
        defer { restore(previous, forKey: Self.conversationBetaKey) }
        body()
    }

    private func withSelectedProvider(_ providerId: String, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let key = WmuxExtensionSidebarSelection.defaultsKey
        let previous = defaults.object(forKey: key)
        defaults.set(providerId, forKey: key)
        defer { restore(previous, forKey: key) }
        body()
    }

    private func restore(_ value: Any?, forKey key: String) {
        let defaults = UserDefaults.standard
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    /// The built-in views must remain selectable even when the experimental
    /// Extensions beta is disabled — the regression hid every one of them.
    @Test
    func builtInViewsAvailableWhenExtensionsBetaDisabled() {
        withExtensionsBeta(false) {
            let availableIDs = Set(WmuxExtensionSidebarSelection.descriptors.map(\.id))
            for builtInID in Self.builtInViewIDs {
                #expect(
                    availableIDs.contains(builtInID),
                    "Built-in sidebar view \(builtInID) is missing from the switcher menu"
                )
            }
        }
    }

    @Test
    func conversationSidebarRequiresBetaAndReleaseGate() {
        withConversationBeta(false) {
            #expect(!WmuxExtensionSidebarSelection.descriptors.map(\.id).contains(
                WmuxExtensionSidebarSelection.conversationSidebarProviderId
            ))
            #expect(
                WmuxExtensionSidebarSelection.effectiveProviderId(
                    WmuxExtensionSidebarSelection.conversationSidebarProviderId,
                    extensionsEnabled: false,
                    customSidebarsEnabled: true,
                    conversationSidebarEnabled: false
                ) == WmuxExtensionSidebarSelection.defaultProviderId
            )
        }
        // The local toggle cannot bypass the remote release gate. The explicit
        // resolver overload remains covered so a remotely enabled rollout can
        // preserve an existing selection while the beta setting is on.
        withConversationBeta(true) {
            #expect(!WmuxExtensionSidebarSelection.descriptors.map(\.id).contains(
                WmuxExtensionSidebarSelection.conversationSidebarProviderId
            ))
            #expect(
                WmuxExtensionSidebarSelection.effectiveProviderId(
                    WmuxExtensionSidebarSelection.conversationSidebarProviderId,
                    extensionsEnabled: false,
                    customSidebarsEnabled: true,
                    conversationSidebarEnabled: true
                ) == WmuxExtensionSidebarSelection.conversationSidebarProviderId
            )
        }
    }

    @Test
    func settingsFileParsesConversationSidebarBetaSetting() throws {
        let defaults = UserDefaults.standard
        let managedKey = SettingCatalog().betaFeatures.conversationSidebar.userDefaultsKey
        let backupsKey = "cmux.settingsFile.backups.v1"
        let previousValue = defaults.object(forKey: managedKey)
        let previousBackups = defaults.data(forKey: backupsKey)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: managedKey)
            } else {
                defaults.removeObject(forKey: managedKey)
            }
            if let previousBackups {
                defaults.set(previousBackups, forKey: backupsKey)
            } else {
                defaults.removeObject(forKey: backupsKey)
            }
        }

        defaults.removeObject(forKey: managedKey)
        defaults.removeObject(forKey: backupsKey)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("conversation-sidebar-settings-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("cmux.json", isDirectory: false)
        try """
        {
          "sidebar": {
            "beta": {
              "conversations": {
                "enabled": true
              }
            }
          }
        }
        """.write(to: file, atomically: true, encoding: .utf8)

        _ = KeyboardShortcutSettingsFileStore(
            primaryPath: file.path,
            fallbackPath: nil,
            startWatching: false
        )

        #expect(defaults.object(forKey: managedKey) as? Bool == true)
    }

    /// Persisting a built-in view as the selection drives the menu's active-view
    /// checkmark to that view. This exercises the same path `showMenu` uses to
    /// decide which item is checked — read the persisted id from `UserDefaults`,
    /// resolve it through `effectiveProviderId`, then look up the descriptor —
    /// rather than asserting on the id in isolation.
    @Test
    func persistedBuiltInSelectionDrivesMenuCheckmark() {
        withExtensionsBeta(false) {
            for builtInID in Self.builtInViewIDs {
                withSelectedProvider(builtInID) {
                    let persisted = UserDefaults.standard.string(forKey: WmuxExtensionSidebarSelection.defaultsKey)
                        ?? WmuxExtensionSidebarSelection.defaultProviderId
                    let effective = WmuxExtensionSidebarSelection.effectiveProviderId(
                        persisted,
                        extensionsEnabled: WmuxExtensionSidebarSelection.isEnabled
                    )
                    let checkedID = WmuxExtensionSidebarSelection.descriptor(for: effective).id
                    #expect(
                        checkedID == builtInID,
                        "Persisted selection \(builtInID) did not drive the menu checkmark (got \(checkedID))"
                    )
                }
            }
        }
    }

    /// The hosted-extensions provider belongs to the experimental Extensions
    /// feature, so the effective selection (which the menu checkmark tracks)
    /// downgrades it to the default sidebar while the beta is off and honors it
    /// while the beta is on. Built-in views resolve to themselves either way —
    /// they are never gated by the flag.
    @Test
    func effectiveSelectionGatesHostedExtensionButNotBuiltInViews() {
        let projectWorktrees = "com.example.cmux.sidebar.project-worktrees"
        #expect(
            WmuxExtensionSidebarSelection.effectiveProviderId(projectWorktrees, extensionsEnabled: false) == projectWorktrees
        )
        #expect(
            WmuxExtensionSidebarSelection.effectiveProviderId(projectWorktrees, extensionsEnabled: true) == projectWorktrees
        )

        let hosted = WmuxExtensionSidebarSelection.hostedExtensionsProviderId
        #expect(
            WmuxExtensionSidebarSelection.effectiveProviderId(hosted, extensionsEnabled: true) == hosted
        )
        #expect(
            WmuxExtensionSidebarSelection.effectiveProviderId(hosted, extensionsEnabled: false) == WmuxExtensionSidebarSelection.defaultProviderId
        )
    }

    /// Selections saved before #13930 used a dotted key. Launch moves them to the
    /// flat key the sidebar's `@AppStorage` reads, and never lets a leftover legacy
    /// value replace a selection made since.
    @Test
    func legacyDottedSelectionKeyMigratesToFlatKey() throws {
        let suiteName = "SidebarProviderMenuRegressionTests.legacyKey.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        // The on-disk key builds before #13930 wrote.
        let legacyKey = "cmuxExtensionSidebar.providerId"
        let projectWorktrees = "com.example.cmux.sidebar.project-worktrees"

        defaults.set(projectWorktrees, forKey: legacyKey)
        WmuxExtensionSidebarSelection.migrateLegacyDefaultsKeyIfNeeded(defaults: defaults)
        #expect(defaults.string(forKey: WmuxExtensionSidebarSelection.defaultsKey) == projectWorktrees)
        #expect(defaults.object(forKey: legacyKey) == nil)

        defaults.set("com.example.cmux.sidebar.attention-queue", forKey: legacyKey)
        WmuxExtensionSidebarSelection.migrateLegacyDefaultsKeyIfNeeded(defaults: defaults)
        #expect(defaults.string(forKey: WmuxExtensionSidebarSelection.defaultsKey) == projectWorktrees)
        #expect(defaults.object(forKey: legacyKey) == nil)
    }

    /// The host renders the selected view through an
    /// `any WmuxSidebarProvider` existential
    /// (`WmuxExtensionSidebarSelection.provider(for:)?.render(snapshot:)`).
    /// `render(snapshot:)` must dynamic-dispatch to the concrete view; if it
    /// instead hits the empty protocol-extension default, every built-in view
    /// renders an empty sidebar even though the provider and workspaces are
    /// present — the second half of #5173. Super Compact lists every workspace
    /// in one section, so its rows must equal the workspace count.
    @Test
    func builtInProviderRendersRowsThroughHostExistential() {
        let snapshot = Self.populatedSnapshot(workspaceCount: 3)
        let provider = WmuxExtensionSidebarSelection.provider(for: "com.example.cmux.sidebar.super-compact")
        #expect(provider != nil, "Super Compact provider should be registered")
        let model = provider?.render(snapshot: snapshot)
        #expect(
            (model?.sections.flatMap(\.rows).count ?? 0) == 3,
            "Selected view rendered no rows through the host existential (empty-sidebar regression)"
        )
    }

    /// `VerticalTabsSidebar.body` decides whether to show the default workspaces
    /// sidebar or an extension sidebar on every render. It used to do that with
    /// `descriptor(for:).id == defaultWorkspacesID`, which rebuilds the full
    /// `descriptors` list — constructing a `SettingCatalog` twice and scanning
    /// the custom-sidebars directory — on every body pass. That per-pass cost was
    /// the multiplier behind the sustained ~100% CPU re-render loop in #5970.
    /// `resolvesToDefaultSidebar(effectiveProviderId:)` is the cheap replacement;
    /// these tests pin that it routes identically to the old descriptor lookup
    /// for every effective selection.
    @Test
    func resolvesToDefaultSidebarMatchesDescriptorRoutingForBuiltInViews() {
        for betaEnabled in [false, true] {
            withExtensionsBeta(betaEnabled) {
                for builtInID in Self.builtInViewIDs {
                    let cheap = WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: builtInID)
                    let viaDescriptor = WmuxExtensionSidebarSelection.descriptor(for: builtInID).id
                        == WmuxSidebarProviderDescriptor.defaultWorkspacesID
                    #expect(
                        cheap == viaDescriptor,
                        "Routing mismatch for \(builtInID) (extensionsBeta=\(betaEnabled)): cheap=\(cheap) descriptor=\(viaDescriptor)"
                    )
                }
                // The default view routes to the workspaces sidebar; every bundled
                // preset routes to an extension sidebar.
                #expect(
                    WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(
                        effectiveProviderId: WmuxExtensionSidebarSelection.defaultProviderId
                    )
                )
                for presetID in Self.builtInViewIDs.dropFirst() {
                    #expect(
                        !WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: presetID),
                        "Bundled preset \(presetID) must route to an extension sidebar, not the default"
                    )
                }
            }
        }
    }

    /// The hosted-extensions provider only appears in `effectiveProviderId`'s
    /// output while the Extensions beta is on, and then it must route to an
    /// extension sidebar (not the default). Matches the descriptor lookup.
    @Test
    func resolvesToDefaultSidebarRoutesHostedExtensionToExtensionSidebar() {
        withExtensionsBeta(true) {
            let hosted = WmuxExtensionSidebarSelection.hostedExtensionsProviderId
            #expect(!WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: hosted))
            #expect(
                WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: hosted)
                    == (WmuxExtensionSidebarSelection.descriptor(for: hosted).id
                        == WmuxSidebarProviderDescriptor.defaultWorkspacesID)
            )
        }
    }

    /// An unknown/stale provider id (e.g. a deleted custom sidebar) has no
    /// renderable provider, so routing falls back to the default workspaces
    /// sidebar — exactly as `descriptor(for:)`'s `?? .defaultWorkspaces` did.
    @Test
    func resolvesToDefaultSidebarFallsBackForUnknownProvider() {
        withExtensionsBeta(true) {
            let unknown = "com.example.cmux.sidebar.does-not-exist-\(UUID().uuidString)"
            #expect(WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: unknown))
            #expect(
                WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: unknown)
                    == (WmuxExtensionSidebarSelection.descriptor(for: unknown).id
                        == WmuxSidebarProviderDescriptor.defaultWorkspacesID)
            )

            // A custom-prefixed selection whose backing file does not exist also
            // falls back to the default sidebar.
            let missingCustom = WmuxExtensionSidebarSelection.customSidebarProviderPrefix
                + "missing-\(UUID().uuidString)"
            #expect(WmuxExtensionSidebarSelection.resolvesToDefaultSidebar(effectiveProviderId: missingCustom))
        }
    }

    /// Custom provider ids are persisted strings, so the fast path must keep the
    /// old descriptor enumeration boundary: only files directly inside the
    /// sidebars directory are renderable.
    @Test
    func customSidebarFileURLRejectsPathTraversalProviderIds() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-custom-sidebar-test-\(UUID().uuidString)", isDirectory: true)
        let sidebarsDirectory = root.appendingPathComponent("sidebars", isDirectory: true)
        try FileManager.default.createDirectory(at: sidebarsDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let validName = "valid-\(UUID().uuidString)"
        let validURL = sidebarsDirectory.appendingPathComponent("\(validName).swift", isDirectory: false)
        try Data().write(to: validURL)
        #expect(
            WmuxExtensionSidebarSelection.customSidebarFileURL(
                forProviderId: WmuxExtensionSidebarSelection.customSidebarProviderPrefix + validName,
                sidebarsDirectory: sidebarsDirectory
            ) == validURL
        )

        let escapedName = "outside-\(UUID().uuidString)"
        let escapedURL = root.appendingPathComponent("\(escapedName).swift", isDirectory: false)
        try Data().write(to: escapedURL)
        #expect(
            WmuxExtensionSidebarSelection.customSidebarFileURL(
                forProviderId: WmuxExtensionSidebarSelection.customSidebarProviderPrefix + "../\(escapedName)",
                sidebarsDirectory: sidebarsDirectory
            ) == nil
        )
    }

    @Test
    func customSidebarOnboardingCreatesDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-sidebar-onboarding-folder-\(UUID().uuidString)", isDirectory: true)
        let directory = root.appendingPathComponent("sidebars", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(!FileManager.default.fileExists(atPath: directory.path))
        let created = try WmuxExtensionSidebarSelection.ensureCustomSidebarsDirectory(directory)
        var isDirectory: ObjCBool = false
        #expect(created == directory)
        #expect(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
    }

    @Test
    func customSidebarOnboardingCreatesValidatedStarterAndDiscoversIt() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-sidebar-onboarding-create-\(UUID().uuidString)", isDirectory: true)
        let directory = root.appendingPathComponent("sidebars", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let template = try #require(CustomSidebarOnboardingAssets().starterTemplate())
        let first = WmuxExtensionSidebarSelection.writeCustomSidebar(
            named: "my-sidebar.swift",
            fileExtension: template.fileExtension,
            source: template.source,
            uniquingIfNeeded: false,
            sidebarsDirectory: directory
        )
        guard case let .created(name, fileURL) = first else {
            Issue.record("Expected starter creation, got \(first)")
            return
        }

        #expect(name == "my-sidebar")
        #expect(fileURL.lastPathComponent == "my-sidebar.swift")
        #expect(CustomSidebarValidator().validate(fileURL: fileURL).errorMessage == nil)
        #expect(
            WmuxExtensionSidebarSelection.discoveredCustomSidebarNames(sidebarsDirectory: directory)
                == ["my-sidebar"]
        )

        #expect(
            WmuxExtensionSidebarSelection.writeCustomSidebar(
                named: "my-sidebar",
                fileExtension: template.fileExtension,
                source: template.source,
                uniquingIfNeeded: false,
                sidebarsDirectory: directory
            ) == .alreadyExists
        )
        #expect(
            WmuxExtensionSidebarSelection.writeCustomSidebar(
                named: "../escape",
                fileExtension: template.fileExtension,
                source: template.source,
                uniquingIfNeeded: false,
                sidebarsDirectory: directory
            ) == .invalidName
        )
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("escape.swift").path))
    }

    @Test
    func customSidebarOnboardingCopiesBundledExampleWithoutOverwriting() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmux-sidebar-onboarding-example-\(UUID().uuidString)", isDirectory: true)
        let directory = root.appendingPathComponent("sidebars", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let template = try #require(CustomSidebarOnboardingAssets().exampleTemplate(id: "agents-board"))
        let first = WmuxExtensionSidebarSelection.writeCustomSidebar(
            named: template.suggestedName,
            fileExtension: template.fileExtension,
            source: template.source,
            uniquingIfNeeded: true,
            sidebarsDirectory: directory
        )
        let second = WmuxExtensionSidebarSelection.writeCustomSidebar(
            named: template.suggestedName,
            fileExtension: template.fileExtension,
            source: template.source,
            uniquingIfNeeded: true,
            sidebarsDirectory: directory
        )

        guard case let .created(firstName, firstURL) = first,
              case let .created(secondName, secondURL) = second else {
            Issue.record("Expected two example copies, got \(first) and \(second)")
            return
        }

        #expect(firstName == "agents-board")
        #expect(secondName == "agents-board-2")
        #expect(firstURL != secondURL)
        #expect(CustomSidebarValidator().validate(fileURL: firstURL).errorMessage == nil)
        #expect(CustomSidebarValidator().validate(fileURL: secondURL).errorMessage == nil)
        #expect(
            WmuxExtensionSidebarSelection.discoveredCustomSidebarNames(sidebarsDirectory: directory)
                == ["agents-board", "agents-board-2"]
        )
    }

    @Test(arguments: [false, true])
    func customSidebarCreationPreservesCaseCollisions(uniquing: Bool) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sidebar-case-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let existing = directory.appendingPathComponent("Focus.swift")
        let original = "Text(\"User-authored sidebar\")"
        try original.write(to: existing, atomically: true, encoding: .utf8)
        let result = WmuxExtensionSidebarSelection.writeCustomSidebar(
            named: "focus", fileExtension: "swift", source: "Text(\"New sidebar\")",
            uniquingIfNeeded: uniquing, sidebarsDirectory: directory
        )
        #expect(try String(contentsOf: existing, encoding: .utf8) == original)
        if uniquing {
            #expect(result == .created(name: "focus-2", fileURL: directory.appendingPathComponent("focus-2.swift")))
        } else {
            #expect(result == .alreadyExists)
        }
    }

    @Test
    func customSidebarCreationPreservesDanglingSymlink() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sidebar-link-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let link = directory.appendingPathComponent("focus.swift")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "missing.swift")
        let result = WmuxExtensionSidebarSelection.writeCustomSidebar(
            named: "focus", fileExtension: "swift", source: "Text(\"New sidebar\")",
            uniquingIfNeeded: true, sidebarsDirectory: directory
        )
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: link.path) == "missing.swift")
        #expect(result == .created(name: "focus-2", fileURL: directory.appendingPathComponent("focus-2.swift")))
    }

    private static func populatedSnapshot(workspaceCount: Int) -> WmuxSidebarProviderSnapshot {
        let workspaces = (0..<workspaceCount).map { index in
            WmuxSidebarProviderWorkspace(
                id: UUID(),
                title: "Workspace \(index)",
                customDescription: nil,
                isPinned: false,
                rootPath: "/tmp/ws\(index)",
                projectRootPath: "/tmp/ws\(index)",
                branchSummary: "main",
                remoteDisplayTarget: nil,
                remoteConnectionState: "disconnected",
                unreadCount: 0,
                latestNotificationText: nil,
                listeningPorts: []
            )
        }
        return WmuxSidebarProviderSnapshot(
            sequence: 1,
            selectedWorkspaceId: nil,
            workspaces: workspaces
        )
    }
}
