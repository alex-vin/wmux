import CmuxCloud
import CmuxComputerUse
import AppKit
import CmuxAppKitSupportUI
import CmuxFoundation
import CmuxPanes
import CmuxSettings
import CmuxSettingsUI
import CmuxWorkspaces
import CmuxTestSupport
import SwiftUI
import Observation
import Darwin
import Bonsplit
import UniformTypeIdentifiers
import CmuxTerminal
struct cmuxApp: App {
    /// App-owned settings graph, injected into each SwiftUI hosting root.
    private let settingsRuntime: SettingsRuntime
    /// Single owner of the independently launched Computer Use helper daemon.
    private let computerUseRuntimeService: ComputerUseRuntimeService

    /// App-owned auth graph injected into the delegate and auth consumers.
    private let authComposition: MacAuthComposition
    /// Composition-root owner for the config-backed automation bridge.
    private let automationEngine: AutomationEngine
    private let browserDataImportCoordinator: BrowserDataImportCoordinator
    @StateObject private var tabManager: TabManager
    @StateObject private var notificationStore: TerminalNotificationStore
    @StateObject var closedItemHistoryStore: ClosedItemHistoryStore
    @StateObject private var sidebarState: SidebarState
    @State private var keyboardShortcutSettingsObserver = KeyboardShortcutSettingsObserver.shared
    @AppStorage(AppearanceSettings.appearanceModeKey) private var appearanceMode = AppearanceSettings.defaultMode.rawValue
    @AppStorage(TitlebarControlsStyle.storageKey) private var titlebarControlsStyle = TitlebarControlsStyle.defaultRawValue
    @AppStorage(DevBuildBannerDebugSettings.sidebarBannerVisibleKey)
    private var showSidebarDevBuildBanner = DevBuildBannerDebugSettings.defaultShowSidebarBanner
    @AppStorage(SocketControlSettings.appStorageKey) private var socketControlMode = SocketControlSettings.defaultMode.rawValue
    @AppStorage(BrowserToolbarAccessorySpacingDebugSettings.key) private var browserToolbarAccessorySpacingRaw = BrowserToolbarAccessorySpacingDebugSettings.defaultSpacing
    @State private var aboutWindowController: AboutWindowController?
    @State private var browserFocusModeMenuRevision = 0
    @State private var browserAvailabilityMenuRevision = 0
    @State var historyMenuCoordinator: HistoryMenuCoordinator
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var browserToolbarAccessorySpacing: Int {
        BrowserToolbarAccessorySpacingDebugSettings.resolved(browserToolbarAccessorySpacingRaw)
    }

    init() {
        // Gather settings package dependencies once. The runtime itself
        // is assigned after the saved language override below, because
        // it owns localized search-index text for the process lifetime.
        let settingsCatalog = SettingCatalog()
        let configFileURL = CmuxConfigLocation().userConfigFile
        // Relocate a pre-existing socket password out of the legacy
        // Application Support directory before any store reads it. The CLI reads
        // this file on every agent hook, and a cross-identity reach into
        // Application Support triggers the macOS Sequoia "access data from other
        // apps" prompt; the password now lives in the non-protected cmux state
        // directory (https://github.com/manaflow-ai/cmux/issues/5146). The app
        // owns its Application Support data, so it can perform this move silently.
        // This App initializer is the composition root, so it is where the
        // concrete `FileManager.default` is named for the package's injected seams.
        SocketControlPasswordStore.migrateLegacyApplicationSupportPasswordFileIfNeeded(fileManager: .default)
        // Secrets live in their own 0600 files under the cmux state directory,
        // the same directory (and `socket-control-password` file) the socket
        // auth path reads via SocketControlPasswordStore, so the Settings UI
        // and the listener share one source of truth.
        let secretBaseDirectory = SocketControlPasswordStore.defaultPasswordFileURL(fileManager: .default)?
            .deletingLastPathComponent()
            ?? CmuxStateDirectory.url(homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        let secretStore = SecretFileStore(baseDirectory: secretBaseDirectory)

        // Lift any plaintext socket-control password out of `cmux.json` into the
        // secure store, then scrub it from the config. This runs here, in the App
        // initializer, on purpose: it completes before the managed-config layer
        // (`CmuxSettingsFileStore`, loaded later during app launch) reads the
        // file, so removing the key can never be misread as a removed managed
        // override that would trigger a restore. The secure file the migration
        // writes is the same one both the Settings UI (via `secretStore`) and the
        // socket listener (via `SocketControlPasswordStore`) read.
        let socketPasswordStore = SocketControlPasswordStore()
        let secretMigrationTimestamp: String = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime]
            return formatter.string(from: Date())
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "-", with: "")
        }()
        PlaintextSecretMigration.scrub(
            plaintextKeyPath: ["automation", "socketPassword"],
            configURL: configFileURL,
            loadCurrentSecret: { (try? socketPasswordStore.loadPassword()) ?? nil },
            saveSecret: { try socketPasswordStore.savePassword($0) },
            backupTimestamp: secretMigrationTimestamp
        )
        let authComposition = MacAuthComposition()
        let browserDataImportCoordinator = BrowserDataImportCoordinator()
        let notificationStore = TerminalNotificationStore.shared
        let closedItemHistoryStore = ClosedItemHistoryStore.shared
        let sidebarState = SidebarState()
        self.authComposition = authComposition
        self.browserDataImportCoordinator = browserDataImportCoordinator

        // If invoked with CLI-style arguments (e.g. `cmux hooks setup`), exec the
        // bundled CLI at Contents/Resources/bin/cmux. The GUI binary and the CLI
        // share the name `cmux`, so if the GUI's Contents/MacOS leaks onto $PATH
        // (which happens for any shell descended from this process), bare `cmux`
        // resolves here instead of the CLI. See
        // https://github.com/manaflow-ai/cmux/issues/4678.
        // cmux ships a universal binary so it still supports Intel Macs, but a
        // stale LaunchServices architecture preference can pin the app to its
        // x86_64 slice on Apple Silicon, running the whole process tree under
        // Rosetta (macOS 26 deprecation dialog; translated child shells and
        // toolchains). `LSArchitecturePriority` in Info.plist fixes future
        // launches; this corrects an already-mis-pinned install by re-execing the
        // arm64 slice in place. It runs *before* CLI forwarding so a translated
        // GUI binary invoked with CLI-style arguments is re-execed natively first
        // and the forwarded bundled CLI then inherits the native arch too. The
        // re-exec preserves argv and re-enters this initializer, so forwarding
        // proceeds normally in the native process. No-op on Intel and on native
        // launches. See https://github.com/manaflow-ai/cmux/issues/753.
        RosettaNativeRelaunch.relaunchNativelyIfNeeded()

        CLIForwardingLaunchRouter.forwardToBundledCLIIfNeeded()

        StartupBreadcrumbLog.append("app.init.begin")
        UITestLaunchManifest.applyIfPresent()
        StartupBreadcrumbLog.append("app.init.uiTestManifest.applied")

        if SocketControlSettings.shouldBlockUntaggedDebugLaunch() {
            StartupBreadcrumbLog.append("app.init.blockUntaggedDebugLaunch")
            Self.terminateForMissingLaunchTag()
        }

        Self.configureGhosttyEnvironment()
        StartupBreadcrumbLog.append("app.init.ghosttyEnvironment.configured")
        let computerUsePaths = ComputerUseRuntimePaths()
        setenv(
            ComputerUseRuntimePaths.daemonSocketEnvironmentKey,
            computerUsePaths.daemonSocketURL.path,
            1
        )
        setenv(
            ComputerUseRuntimePaths.codexDaemonSocketEnvironmentKey,
            computerUsePaths.codexDaemonSocketURL.path,
            1
        )
        setenv(
            ComputerUseRuntimePaths.stateDirectoryEnvironmentKey,
            computerUsePaths.stateDirectoryURL.path,
            1
        )
        setenv(
            ComputerUseRuntimePaths.runtimeScopeEnvironmentKey,
            computerUsePaths.scope,
            1
        )
        // Codex app approval authenticates the MCP broker as the exact
        // executable already serving this cmux-owned helper generation.
        // Both agent wrappers use this installed helper as their MCP client;
        // the app ships no other cmux-cua copy, and the wrappers validate the
        // path before use.
        setenv(
            ComputerUseRuntimePaths.clientExecutableEnvironmentKey,
            computerUsePaths.installedHelperExecutableURL.path,
            1
        )
        // The helper bearer token is written to a private per-user runtime file
        // and read only by the agent wrappers. Never place the capability in the
        // app environment inherited by every terminal child.
        unsetenv(ComputerUseRuntimePaths.authenticationTokenEnvironmentKey)
        setenv(
            ComputerUseRuntimePaths.authenticationTokenFileEnvironmentKey,
            computerUsePaths.authenticationTokenFileURL.path,
            1
        )
        let computerUseRuntimeService = ComputerUseRuntimeService(paths: computerUsePaths)
        self.computerUseRuntimeService = computerUseRuntimeService
        _ = KeyboardShortcutSettings.settingsFileStore
        StartupBreadcrumbLog.append("app.init.keyboardShortcuts.loaded")

        // Reconcile saved language preference before any UI loads
        LanguageSettingsStore(defaults: .standard, domainName: ProcessDefaultsDomain.name).reconcileLanguageOverrideAtLaunch()
        StartupBreadcrumbLog.append("app.init.language.applied")
        let devices = MacDevicesComposition(defaults: .standard, catalog: settingsCatalog)
        let devicesRegistry = devices.registry
        let computersService = devices.computers
        let hostSettingsActions = HostSettingsActions(
            configFileURL: configFileURL,
            computerUseRuntimeService: computerUseRuntimeService,
            browserDataImportCoordinator: browserDataImportCoordinator,
            runComputerUseOnboardingAction: { startingPoint in
                AppDelegate.shared?.computerUseUXCoordinator.presentOnboardingFromSettings(
                    startingAt: startingPoint
                )
            }
        )
        self.settingsRuntime = SettingsRuntime(
            catalog: settingsCatalog,
            userDefaultsStore: devices.defaultsStore,
            jsonStore: JSONConfigStore(fileURL: configFileURL),
            secretStore: secretStore,
            errorLog: SettingsErrorLog(),
            accountFlow: authComposition.accountFlow,
            hostActions: hostSettingsActions,
            shortcutDefaultResolver: Self.makeShortcutDefaultResolver()
        )
        StartupBreadcrumbLog.append("app.init.settingsRuntime.created")

        let startupAppearance = AppearanceSettings.resolvedMode()
        Self.applyAppearance(startupAppearance, duringLaunch: true)
        StartupBreadcrumbLog.append("app.init.appearance.applied", fields: ["mode": startupAppearance.rawValue])
        let defaults = UserDefaults.standard
        CmuxExtensionSidebarSelection.clearStaleTemplatePreviewSelection(defaults: defaults)
        TerminalController.shared.prepareControlHandleRegistryForLaunch(defaults: defaults)
        let workspaceCustomizationStore = WorkspaceCustomizationStore(
            defaults: defaults
        )
        AppBundleIconPersistencePolicy.updateDisableDefault(
            defaults: defaults,
            launchArguments: ProcessInfo.processInfo.arguments
        )
        KeyboardShortcutSettings.settingsFileStore.applyDeferredManagedDefaultSideEffects()
        StartupBreadcrumbLog.append("app.init.keyboardShortcuts.sideEffectsApplied")
        StartupBreadcrumbLog.append("app.init.tabManager.begin")
        let (cloudMachinePinStore, cloudWorkspaceCoordinator) = Self.makeCloudWorkspaceComposition(auth: authComposition)
        let tabManager = TabManager(
            workspaceCustomizationStore: workspaceCustomizationStore,
            nativeSSHConnectionBroker: TerminalController.shared.nativeSSHConnectionBroker,
            cloudWorkspaceSelection: cloudWorkspaceCoordinator.makeSelectionState()
        )
        let historyMenuCoordinator = HistoryMenuCoordinator(
            closedItemHistoryStore: closedItemHistoryStore,
            managerProvider: {
                AppDelegate.shared?.activeTabManagerForCommands(
                    preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                ) ?? tabManager
            },
            mainMenuProvider: { NSApp.mainMenu },
            actions: HistoryMenuActions(
                reopenMostRecentlyClosedWorkspace: { manager in
                    AppDelegate.shared?.reopenMostRecentlyClosedWorkspace(preferredTabManager: manager) == true
                },
                reopenMostRecentlyClosedItem: { manager in
                    AppDelegate.shared?.reopenMostRecentlyClosedItem(preferredTabManager: manager) == true
                },
                reopenClosedHistoryItem: { id, manager in
                    AppDelegate.shared?.reopenClosedHistoryItem(id: id, preferredTabManager: manager) == true
                },
                reopenPreviousSession: {
                    AppDelegate.shared?.reopenPreviousSession() == true
                }
            )
        )
        _tabManager = StateObject(wrappedValue: tabManager)
        _notificationStore = StateObject(wrappedValue: notificationStore)
        _closedItemHistoryStore = StateObject(wrappedValue: closedItemHistoryStore)
        _sidebarState = StateObject(wrappedValue: sidebarState)
        let automationEngine = AutomationEngine(
            workspaceTagsResolver: { workspaceID in
                // Resolve through the app delegate's live window-context index;
                // the bootstrap TabManager can be retired when the first real
                // main window is adopted.
                guard let manager = AppDelegate.shared?.tabManagerFor(tabId: workspaceID),
                      let workspace = manager.workspacesById[workspaceID] else {
                    return []
                }
                return workspace.sidebarStatusEntriesInDisplayOrder().flatMap { entry in
                    [entry.key, entry.value]
                }
            }
        )
        self.automationEngine = automationEngine
        _historyMenuCoordinator = State(initialValue: historyMenuCoordinator)
        StartupBreadcrumbLog.append("app.init.tabManager.complete")
        // Migrate legacy and old-format socket mode values to the new enum.
        if let stored = defaults.string(forKey: SocketControlSettings.appStorageKey) {
            let migrated = SocketControlSettings.migrateMode(stored)
            if migrated.rawValue != stored {
                defaults.set(migrated.rawValue, forKey: SocketControlSettings.appStorageKey)
            }
        } else if let legacy = defaults.object(forKey: SocketControlSettings.legacyEnabledKey) as? Bool {
            defaults.set(legacy ? SocketControlMode.cmuxOnly.rawValue : SocketControlMode.off.rawValue,
                         forKey: SocketControlSettings.appStorageKey)
        }
        // Skip keychain migration for DEV/staging builds. Each tagged build gets a
        // unique bundle ID with its own UserDefaults domain, so migration would run
        // on every launch and trigger a macOS keychain access prompt (the legacy
        // keychain item was created by a differently-signed app).
        let bundleID = Bundle.main.bundleIdentifier
        if !SocketControlSettings.isDebugLikeBundleIdentifier(bundleID)
            && !SocketControlSettings.isStagingBundleIdentifier(bundleID) {
            StartupBreadcrumbLog.append("app.init.keychainMigration.begin")
            SocketControlPasswordStore().migrateLegacyKeychainPasswordIfNeeded(defaults: defaults)
            StartupBreadcrumbLog.append("app.init.keychainMigration.complete")
        }
        migrateSidebarAppearanceDefaultsIfNeeded(defaults: defaults)
        MinimalModeTitlebarDebugSettings.migrateLegacyKeysIfNeeded(defaults: defaults)
        CmuxExtensionSidebarSelection.migrateLegacyDefaultsKeyIfNeeded(defaults: defaults)
        StartupBreadcrumbLog.append("app.init.sidebarDefaults.migrated")

        // UI tests need AppDelegate wiring even if SwiftUI appearance callbacks are skipped.
        StartupBreadcrumbLog.append("app.init.delegate.configure.begin")
        let cloudWorkspaceOperationController = CloudWorkspaceOperationController(
            isAvailable: { cloudWorkspaceCoordinator.isAvailable }
        )
        appDelegate.configure(
            tabManager: tabManager,
            notificationStore: notificationStore,
            sidebarState: sidebarState,
            settingsRuntime: settingsRuntime,
            auth: authComposition,
            cloudMachinePinStore: cloudMachinePinStore,
            cloudWorkspaceCoordinator: cloudWorkspaceCoordinator,
            cloudWorkspaceOperationController: cloudWorkspaceOperationController,
            newMachineSheetPresenter: NewMachineSheetPresenter.shared,
            automationEngine: automationEngine,
            browserDataImportCoordinator: browserDataImportCoordinator,
            computerUseRuntimeService: computerUseRuntimeService,
            devicesRegistry: devicesRegistry,
            computersService: computersService
        )
        hostSettingsActions.cloudActivationCoordinator = appDelegate.cloudActivationCoordinator
        historyMenuCoordinator.refreshIfNeeded()
        StartupBreadcrumbLog.append("app.init.delegate.configured")
    }

    /// Builds the host-owned resolver used by Settings UI shortcut models.
    /// Dynamic right-sidebar defaults depend on app state and must not be
    /// installed into the settings package as process-global mutable state.
    private static func makeShortcutDefaultResolver() -> CmuxSettings.ShortcutDefaultResolver {
        CmuxSettings.ShortcutDefaultResolver { action in
            guard let mode = RightSidebarMode.allCases.first(where: {
                $0.shortcutAction?.rawValue == action.rawValue
            }) else { return .useBuiltIn }
            guard let digit = RightSidebarMode.positionalDigit(for: mode) else {
                return .stroke(nil)
            }
            return .stroke(CmuxSettings.ShortcutStroke(key: String(digit), control: true))
        }
    }

    private static func terminateForMissingLaunchTag() -> Never {
        let message = "error: refusing to launch untagged cmux DEV; start with ./scripts/reload.sh --tag <name> (or set CMUX_TAG for test harnesses)"
        fputs("\(message)\n", stderr)
        fflush(stderr)
        NSLog("%@", message)
        Darwin.exit(64)
    }

    private static func configureGhosttyEnvironment() {
        let fileManager = FileManager.default
        let currentResourcesDir = getenv("GHOSTTY_RESOURCES_DIR").flatMap { String(cString: $0) }
        if let resolvedResourcesDir = resolvedGhosttyResourcesDirectory(
            currentValue: currentResourcesDir,
            bundleResourceURL: Bundle.main.resourceURL,
            fileManager: fileManager
        ) {
            setenv("GHOSTTY_RESOURCES_DIR", resolvedResourcesDir, 1)
        }

        if getenv("TERMINFO") == nil,
           let terminfoURL = Bundle.main.resourceURL?.appendingPathComponent("terminfo"),
           fileManager.fileExists(atPath: terminfoURL.path) {
            setenv("TERMINFO", terminfoURL.path, 1)
        }

        if getenv("TERM") == nil {
            setenv("TERM", TerminalSurface.managedTerminalType, 1)
        }

        if getenv("COLORTERM") == nil {
            setenv("COLORTERM", TerminalSurface.managedColorTerm, 1)
        }

        if getenv("TERM_PROGRAM") == nil {
            setenv("TERM_PROGRAM", TerminalSurface.managedTerminalProgram, 1)
        }

        if let resourcesDir = getenv("GHOSTTY_RESOURCES_DIR").flatMap({ String(cString: $0) }) {
            let resourcesURL = URL(fileURLWithPath: resourcesDir)
            let resourcesParent = resourcesURL.deletingLastPathComponent()
            let dataDir = resourcesParent.path
            let manDir = resourcesParent.appendingPathComponent("man").path

            prependEnvPathIfMissing(
                "XDG_DATA_DIRS",
                path: dataDir,
                defaultValue: "/usr/local/share:/usr/share"
            )
            prependEnvPathIfMissing("MANPATH", path: manDir)
        }
    }

    static func resolvedGhosttyResourcesDirectory(
        currentValue: String?,
        bundleResourceURL: URL?,
        ghosttyAppResources: String = "/Applications/Ghostty.app/Contents/Resources/ghostty",
        fileManager: FileManager = .default
    ) -> String? {
        let bundledGhosttyURL = bundleResourceURL?.appendingPathComponent("ghostty")
        // Tagged cmux builds may inherit GHOSTTY_RESOURCES_DIR from another running
        // cmux instance. Prefer this app's bundled resources when they are present.
        if let bundledGhosttyURL,
           fileManager.fileExists(atPath: bundledGhosttyURL.path),
           fileManager.fileExists(atPath: bundledGhosttyURL.appendingPathComponent("themes").path) {
            return bundledGhosttyURL.path
        }

        if let currentValue = currentValue?.trimmingCharacters(in: .whitespacesAndNewlines),
           !currentValue.isEmpty,
           fileManager.fileExists(atPath: currentValue) {
            return currentValue
        }

        if fileManager.fileExists(atPath: ghosttyAppResources) {
            return ghosttyAppResources
        }

        if let bundledGhosttyURL,
           fileManager.fileExists(atPath: bundledGhosttyURL.path) {
            return bundledGhosttyURL.path
        }

        return nil
    }

    private static func prependEnvPathIfMissing(_ key: String, path: String, defaultValue: String? = nil) {
        if path.isEmpty { return }
        var current = getenv(key).flatMap { String(cString: $0) } ?? ""
        if current.isEmpty, let defaultValue {
            current = defaultValue
        }
        if current.split(separator: ":").contains(Substring(path)) {
            return
        }
        let updated = current.isEmpty ? path : "\(path):\(current)"
        setenv(key, updated, 1)
    }

    private func migrateSidebarAppearanceDefaultsIfNeeded(defaults: UserDefaults) {
        let migrationKey = "sidebarAppearanceDefaultsVersion"
        let targetVersion = 1
        guard defaults.integer(forKey: migrationKey) < targetVersion else { return }

        func normalizeHex(_ value: String) -> String {
            value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "#", with: "")
                .uppercased()
        }

        func approximatelyEqual(_ lhs: Double, _ rhs: Double, tolerance: Double = 0.0001) -> Bool {
            abs(lhs - rhs) <= tolerance
        }

        let material = defaults.string(forKey: "sidebarMaterial") ?? SidebarMaterialOption.sidebar.rawValue
        let blendMode = defaults.string(forKey: "sidebarBlendMode") ?? SidebarBlendModeOption.behindWindow.rawValue
        let state = defaults.string(forKey: "sidebarState") ?? SidebarStateOption.followWindow.rawValue
        let tintHex = defaults.string(forKey: "sidebarTintHex") ?? "#101010"
        let tintOpacity = defaults.object(forKey: "sidebarTintOpacity") as? Double ?? 0.54
        let blurOpacity = defaults.object(forKey: "sidebarBlurOpacity") as? Double ?? 0.79
        let cornerRadius = defaults.object(forKey: "sidebarCornerRadius") as? Double ?? 0.0

        let usesLegacyDefaults =
            material == SidebarMaterialOption.sidebar.rawValue &&
            blendMode == SidebarBlendModeOption.behindWindow.rawValue &&
            state == SidebarStateOption.followWindow.rawValue &&
            normalizeHex(tintHex) == "101010" &&
            approximatelyEqual(tintOpacity, 0.54) &&
            approximatelyEqual(blurOpacity, 0.79) &&
            approximatelyEqual(cornerRadius, 0.0)

        if usesLegacyDefaults {
            let preset = SidebarPresetOption.nativeSidebar
            defaults.set(preset.rawValue, forKey: "sidebarPreset")
            defaults.set(preset.material.rawValue, forKey: "sidebarMaterial")
            defaults.set(preset.blendMode.rawValue, forKey: "sidebarBlendMode")
            defaults.set(preset.state.rawValue, forKey: "sidebarState")
            defaults.set(preset.tintHex, forKey: "sidebarTintHex")
            defaults.set(preset.tintOpacity, forKey: "sidebarTintOpacity")
            defaults.set(preset.blurOpacity, forKey: "sidebarBlurOpacity")
            defaults.set(preset.cornerRadius, forKey: "sidebarCornerRadius")
        }

        defaults.set(targetVersion, forKey: migrationKey)
    }

    var body: some Scene {
        WindowGroup {
            MainWindowBootstrapView()
                .settingsRuntime(settingsRuntime)
                .cmuxFontMagnificationEnvironment()
                .cmuxAppearanceColorScheme(appearanceMode)
                .onAppear {
#if DEBUG
                    if ProcessInfo.processInfo.environment["CMUX_UI_TEST_MODE"] == "1" {
                        AppDelegate.shared?.updateLog.append("ui test: cmuxApp onAppear")
                    }
#endif
                    bootstrapMainWindowScene()
                }
                .onChange(of: appearanceMode) { _ in
                    applyAppearance()
                }
                .onChange(of: socketControlMode) { _ in
                    updateSocketController()
                }
                .onReceive(NotificationCenter.default.publisher(for: .browserFocusModeStateDidChange)) { _ in
                    browserFocusModeMenuRevision &+= 1
                }
                // `BrowserAvailabilityMonitor` owns watching the gate's
                // entrypoints, so the menus follow that one signal and
                // re-evaluate on a real change instead of on every defaults
                // write.
                .onReceive(NotificationCenter.default.publisher(for: BrowserAvailabilityMonitor.didChangeNotification)) { _ in
                    browserAvailabilityMenuRevision &+= 1
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appSettings) {
                splitCommandButton(title: String(localized: "menu.app.settings", defaultValue: "Settings…"), shortcut: menuShortcut(for: .openSettings)) {
                    appDelegate.openPreferencesWindow(debugSource: "menu.cmdComma")
                }
                Button(AppDelegate.actionsAndLaunchersMenuTitle) {
                    appDelegate.presentActionsAndLaunchersCustomization(
                        preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                    )
                }
                Button(String(localized: "menu.app.openCmuxSettingsFile", defaultValue: "Open cmux.json")) {
                    openCmuxSettingsFileInEditor()
                }
                Button(String(localized: "menu.app.ghosttySettings", defaultValue: "Ghostty Settings…")) {
                    GhosttyApp.shared.openConfigurationInTextEdit()
                }
                splitCommandButton(title: String(localized: "menu.app.reloadConfiguration", defaultValue: "Reload Configuration"), shortcut: menuShortcut(for: .reloadConfiguration)) {
                    dispatchReloadConfigurationMenuCommand()
                }
                Button(String(localized: "menu.app.makeDefaultTerminal", defaultValue: "Make cmux the Default Terminal")) {
                    DefaultTerminalUserAction.setAsDefault(debugSource: "menu.makeDefaultTerminal")
                }
                Divider()
                Toggle(
                    String(localized: "menu.app.keepMacAwake", defaultValue: "Keep Mac Awake"),
                    isOn: Binding(
                        get: { appDelegate.caffeineController.isEnabled },
                        set: { appDelegate.caffeineController.setEnabled($0) }
                    )
                )
            }

            CommandGroup(replacing: .appInfo) {
                Button(String(localized: "menu.app.about", defaultValue: "About cmux")) {
                    showAboutPanel()
                }
            }

            CommandGroup(replacing: .appTermination) {
                splitCommandButton(title: String(localized: "menu.quitCmux", defaultValue: "Quit cmux"), shortcut: menuShortcut(for: .quit)) {
                    AppDelegate.requestApplicationTermination()
                }
            }

            CommandMenu(String(localized: "menu.notifications.title", defaultValue: "Notifications")) {
                let snapshot = notificationMenuSnapshot

                Button(snapshot.stateHintTitle) {}
                    .disabled(true)

                if !snapshot.recentNotifications.isEmpty {
                    Divider()

                    ForEach(snapshot.recentNotifications) { notification in
                        Button(notificationMenuItemTitle(for: notification)) {
                            openNotificationFromMainMenu(notification)
                        }
                    }

                    Divider()
                }

                splitCommandButton(title: String(localized: "menu.notifications.show", defaultValue: "Show Notifications"), shortcut: menuShortcut(for: .showNotifications)) {
                    showNotificationsPopover()
                }

                splitCommandButton(title: String(localized: "menu.notifications.jumpToUnread", defaultValue: "Jump to Latest Unread"), shortcut: menuShortcut(for: .jumpToUnread)) {
                    appDelegate.jumpToLatestUnread()
                }
                .disabled(!snapshot.hasUnreadNotifications)

                splitCommandButton(title: String(localized: "menu.notifications.toggleUnread", defaultValue: "Toggle Unread"), shortcut: menuShortcut(for: .toggleUnread)) {
                    appDelegate.toggleFocusedNotificationUnread()
                }
                .disabled(activeTabManager.selectedWorkspace == nil)

                splitCommandButton(
                    title: String(localized: "menu.notifications.markAllRead", defaultValue: "Mark All Read"),
                    shortcut: menuShortcut(for: .markAllNotificationsRead)
                ) {
                    notificationStore.markAllRead()
                }
                .disabled(!snapshot.hasUnreadNotifications)

                splitCommandButton(
                    title: String(localized: "menu.notifications.clearAll", defaultValue: "Clear All"),
                    shortcut: menuShortcut(for: .clearAllNotifications)
                ) {
                    notificationStore.clearAll()
                }
                .disabled(!snapshot.hasNotifications)
            }

#if DEBUG
            CommandMenu("Debug") {
                Button("New Tab With Lorem Search Text") {
                    appDelegate.openDebugLoremTab(nil)
                }

                Button("New Tab With Large Scrollback") {
                    appDelegate.openDebugScrollbackTab(nil)
                }

                IrohAndAgentSessionDebugMenuButtons(
                    openReact: { appDelegate.openDebugAgentSessionReact(nil) },
                    openSolid: { appDelegate.openDebugAgentSessionSolid(nil) }
                )

                Button("Open Workspaces for All Workspace Colors") {
                    appDelegate.openDebugColorComparisonWorkspaces(nil)
                }

                CanvasDebugMenuButtons(
                    workspace: activeTabManager.selectedWorkspace,
                    openStressWorkspacesWithLoadedSurfaces: {
                        appDelegate.openDebugStressWorkspacesWithLoadedSurfaces(nil)
                    }
                )


                Menu(
                    String(
                        localized: "debug.menu.browserToolbarButtonSpacing",
                        defaultValue: "Browser Toolbar Button Spacing"
                    )
                ) {
                    ForEach(BrowserToolbarAccessorySpacingDebugSettings.supportedValues, id: \.self) { spacing in
                        Button {
                            browserToolbarAccessorySpacingRaw = spacing
                        } label: {
                            if browserToolbarAccessorySpacing == spacing {
                                Label {
                                    Text(verbatim: "\(spacing)")
                                } icon: {
                                    Image(systemName: "checkmark")
                                }
                            } else {
                                Text(verbatim: "\(spacing)")
                            }
                        }
                    }
                }

                Toggle(
                    String(localized: "debug.devBuildBanner.show", defaultValue: "Show Dev Build Banner"),
                    isOn: $showSidebarDevBuildBanner
                )

                Divider()

                Picker("Titlebar Controls Style", selection: $titlebarControlsStyle) {
                    ForEach(TitlebarControlsStyle.allCases) { style in
                        Text(style.menuTitle).tag(style.rawValue)
                    }
                }

                Divider()

                Button(String(localized: "menu.updateLogs.copyFocusLogs", defaultValue: "Copy Focus Logs")) {
                    appDelegate.copyFocusLogs(nil)
                }

                Divider()

                Button("Trigger Sentry Test Crash") {
                    appDelegate.triggerSentryTestCrash(nil)
                }
            }
#endif

            // New tab commands
            CommandGroup(replacing: .newItem) {
                splitCommandButton(title: String(localized: "menu.file.newWindow", defaultValue: "New Window"), shortcut: menuShortcut(for: .newWindow)) {
                    appDelegate.openNewMainWindow(nil)
                }

                splitCommandButton(title: String(localized: "menu.file.newWorkspace", defaultValue: "New Workspace"), shortcut: menuShortcut(for: .newTab)) {
                    if let appDelegate = AppDelegate.shared {
                        appDelegate.performNewWorkspaceAction(
                            tabManager: activeTabManager,
                            debugSource: "menu.newWorkspace",
                            localOnly: true
                        )
                    } else {
                        activeTabManager.addWorkspaceIfActive()
                    }
                }

                // In a remote-tmux mirror window, plain New Workspace (above) spawns a
                // tmux session on the window's host, leaving no way to open LOCAL work
                // there. Offer an explicit escape hatch, shown only when New Workspace
                // would go remote so it never clutters ordinary windows.
                if newLocalWorkspaceMenuItemVisible {
                    splitCommandButton(title: String(localized: "menu.file.newLocalWorkspace", defaultValue: "New Local Workspace"), shortcut: menuShortcut(for: .newLocalWorkspace)) {
                        AppDelegate.shared?.performNewLocalWorkspaceAction(
                            tabManager: activeTabManager,
                            debugSource: "menu.newLocalWorkspace"
                        )
                    }
                }

                if offersBrowserMenuItems {
                    splitCommandButton(title: String(localized: "menu.file.newBrowserWorkspace", defaultValue: "New Browser Workspace"), shortcut: menuShortcut(for: .newBrowserWorkspace)) {
                        if let appDelegate = AppDelegate.shared {
                            appDelegate.performNewBrowserWorkspaceAction(
                                tabManager: activeTabManager,
                                debugSource: "menu.newBrowserWorkspace"
                            )
                        } else if BrowserAvailabilitySettings.isEnabled() {
                            // Last-resort fallback for a missing AppDelegate; keep
                            // the browser-availability gate identical to the
                            // shared action path.
                            activeTabManager.addWorkspaceIfActive(initialSurface: .browser)
                        }
                    }
                }

                if CmuxFeatureFlags.shared.isSimulatorEnabled {
                    Button(String(localized: "menu.file.newSimulatorPane", defaultValue: "New Simulator Pane")) {
                        performNewSimulatorPaneFromMenu()
                    }
                }

                splitCommandButton(title: String(localized: "menu.file.newWorkspaceGroup", defaultValue: "New Workspace Group"), shortcut: menuShortcut(for: .newWorkspaceGroup)) {
                    _ = AppDelegate.shared?.createEmptyWorkspaceGroup(
                        tabManager: activeTabManager,
                        preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                    )
                }

                splitCommandButton(title: String(localized: "menu.file.openFolder", defaultValue: "Open Folder…"), shortcut: menuShortcut(for: .openFolder)) {
                    AppDelegate.shared?.showOpenFolderPanel()
                }

                Button(
                    String(
                        localized: "menu.file.openFolderInVSCodeInline",
                        defaultValue: "Open Folder in VS Code (Inline)…"
                    )
                ) {
                    AppDelegate.shared?.showOpenFolderInInlineVSCodePanel()
                }
                .disabled(!TerminalDirectoryOpenTarget.vscodeInline.isAvailable())
            }

            // Close tab/workspace
            CommandGroup(after: .newItem) {
                splitCommandButton(title: String(localized: "menu.file.goToWorkspace", defaultValue: "Go to Workspace…"), shortcut: menuShortcut(for: .goToWorkspace)) {
                    let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow
                    NotificationCenter.default.post(name: .commandPaletteSwitcherRequested, object: targetWindow)
                }

                splitCommandButton(title: String(localized: "menu.file.commandPalette", defaultValue: "Command Palette…"), shortcut: menuShortcut(for: .commandPalette)) {
                    let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow
                    NotificationCenter.default.post(name: .commandPaletteRequested, object: targetWindow)
                }

                Divider()

                // Terminal semantics:
                // The Close Tab shortcut closes the focused tab/surface with confirmation
                // when needed. By default, closing the last surface also closes the
                // workspace and the window if it was also the last workspace.
                // Users can opt into keeping the workspace open instead.
                splitCommandButton(title: String(localized: "menu.file.closeTab", defaultValue: "Close Tab"), shortcut: menuShortcut(for: .closeTab)) {
                    closePanelOrWindow()
                }

                splitCommandButton(title: String(localized: "menu.file.closeOtherTabs", defaultValue: "Close Other Tabs in Pane"), shortcut: menuShortcut(for: .closeOtherTabsInPane)) {
                    closeOtherTabsInFocusedPane()
                }
                .disabled(!activeTabManager.canCloseOtherTabsInFocusedPane())

                // The Close Workspace shortcut closes the current workspace with confirmation
                // when needed. If this is the last workspace, it closes the window.
                splitCommandButton(title: String(localized: "menu.file.closeWorkspace", defaultValue: "Close Workspace"), shortcut: menuShortcut(for: .closeWorkspace)) {
                    closeTabOrWindow()
                }

                Menu(String(localized: "commandPalette.switcher.workspaceLabel", defaultValue: "Workspace")) {
                    workspaceCommandMenuContent(manager: activeTabManager)
                }

            }

            // Find
            CommandGroup(after: .textEditing) {
                Menu(String(localized: "menu.find.title", defaultValue: "Find")) {
                    let restoreFindTargetFocus = {
                        _ = AppDelegate.shared?.restoreFocusedMainPanelFocusFromRightSidebar(
                            preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                        )
                    }

                    splitCommandButton(title: String(localized: "menu.find.find", defaultValue: "Find…"), shortcut: menuShortcut(for: .find)) {
#if DEBUG
                        cmuxDebugLog("find.menu Cmd+F fired")
#endif
                        if !performFocusedBrowserAction(.startFind) {
                            _ = AppDelegate.shared?.performFindShortcutInActiveMainWindow(
                                preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                            )
                        }
                    }

                    splitCommandButton(title: String(localized: "menu.find.findInDirectory", defaultValue: "Find in Directory…"), shortcut: menuShortcut(for: .findInDirectory)) {
                        _ = AppDelegate.shared?.focusFileSearchInActiveMainWindow(
                            preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                        )
                    }

                    splitCommandButton(title: String(localized: "menu.find.findNext", defaultValue: "Find Next"), shortcut: menuShortcut(for: .findNext)) {
                        if !performFocusedBrowserAction(.findNext) {
                            restoreFindTargetFocus()
                            activeTabManager.findNext()
                        }
                    }

                    splitCommandButton(title: String(localized: "menu.find.findPrevious", defaultValue: "Find Previous"), shortcut: menuShortcut(for: .findPrevious)) {
                        if !performFocusedBrowserAction(.findPrevious) {
                            restoreFindTargetFocus()
                            activeTabManager.findPrevious()
                        }
                    }

                    Divider()

                    splitCommandButton(title: String(localized: "menu.find.hideFindBar", defaultValue: "Hide Find Bar"), shortcut: menuShortcut(for: .hideFind)) {
                        if !performFocusedBrowserAction(.hideFind) {
                            restoreFindTargetFocus()
                            activeTabManager.hideFind()
                        }
                    }
                    .disabled(!activeFindIsVisible)

                    Divider()

                    splitCommandButton(title: String(localized: "menu.find.useSelectionForFind", defaultValue: "Use Selection for Find"), shortcut: menuShortcut(for: .useSelectionForFind)) {
                        restoreFindTargetFocus()
                        activeTabManager.searchSelection()
                    }
                    .disabled(!(activeTabManager.canUseSelectionForFind))

                    Divider()

                    splitCommandButton(title: String(localized: "menu.find.sendCtrlFToTerminal", defaultValue: "Send Ctrl-F to Terminal"), shortcut: menuShortcut(for: .sendCtrlFToTerminal)) {
                        // Restore focus to the terminal if the right sidebar grabbed it, then
                        // forward a faithfully-encoded Ctrl-F (e.g. Claude Code force-stop).
                        restoreFindTargetFocus()
                        if !activeTabManager.sendCtrlFToFocusedTerminal() {
                            NSSound.beep()
                        }
                    }
                    .disabled(activeTabManager.selectedTerminalPanel == nil)
                }
            }

            windowAndViewCommands
        }

        // Settings is an AppKit-owned window (SettingsWindowPresenter /
        // SettingsWindowFactory), not a SwiftUI Window scene: openWindow(id:)
        // could silently no-op and leave menu/⌘,/CLI opens dead until app
        // restart (https://github.com/manaflow-ai/cmux/issues/7777).

        Window(String(localized: "settings.config.windowTitle", defaultValue: "Config"), id: ConfigSettingsView.windowID) {
            ConfigSettingsView()
                .settingsRuntime(settingsRuntime)
                .cmuxFontMagnificationEnvironment()
                .cmuxAppearanceColorScheme(appearanceMode)
        }
    }
    /// Presents window navigation and stateful View commands for the focused content.
    @CommandsBuilder
    private var windowAndViewCommands: some Commands {
        CommandGroup(after: .windowArrangement) {
            Button(String(localized: "menu.window.taskManager", defaultValue: "Task Manager...")) {
                TaskManagerWindowController.shared.show()
            }
        }
        helpCommands
        historyCommands
        CommandGroup(after: .toolbar) {
            splitCommandButton(
                title: String(localized: "shortcut.focusTextBoxInput.label", defaultValue: "Focus TextBox Input"),
                shortcut: menuShortcut(for: .focusTextBoxInput)
            ) {
                _ = AppDelegate.shared?.performFocusTextBoxInputShortcut(
                    preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                )
            }

            splitCommandButton(title: String(localized: "menu.view.toggleRightSidebar", defaultValue: "Toggle Right Sidebar"), shortcut: menuShortcut(for: .toggleRightSidebar)) {
                if AppDelegate.shared?.toggleRightSidebarInActiveMainWindow(
                    preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                ) != true {
                    NSSound.beep()
                }
            }

            splitCommandButton(title: String(localized: "menu.view.focusRightSidebar", defaultValue: "Toggle Right Sidebar Focus"), shortcut: menuShortcut(for: .focusRightSidebar)) {
                if AppDelegate.shared?.toggleRightSidebarKeyboardFocusInActiveMainWindow() != true {
                    if AppDelegate.shared?.focusRightSidebarInActiveMainWindow(
                        preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
                    ) != true {
                        NSSound.beep()
                    }
                }
            }
            Divider()
            surfaceNavigationCommandButtons()
            splitCommandButton(title: String(localized: "menu.view.back", defaultValue: "Back"), shortcut: menuShortcut(for: .browserBack)) {
                _ = performFocusedBrowserAction(.back)
            }

            splitCommandButton(title: String(localized: "menu.view.forward", defaultValue: "Forward"), shortcut: menuShortcut(for: .browserForward)) {
                _ = performFocusedBrowserAction(.forward)
            }

            splitCommandButton(title: String(localized: "menu.view.reloadPage", defaultValue: "Reload Page"), shortcut: menuShortcut(for: .browserReload)) {
                _ = performFocusedBrowserAction(.reload)
            }

            splitCommandButton(title: String(localized: "menu.view.toggleDevTools", defaultValue: "Toggle Developer Tools"), shortcut: menuShortcut(for: .toggleBrowserDeveloperTools)) {
                if !performFocusedBrowserAction(.toggleDeveloperTools) {
                    NSSound.beep()
                }
            }
            splitCommandButton(title: String(localized: "menu.view.showJSConsole", defaultValue: "Show JavaScript Console"), shortcut: menuShortcut(for: .showBrowserJavaScriptConsole)) {
                if !performFocusedBrowserAction(.showJavaScriptConsole) {
                    NSSound.beep()
                }
            }
            splitCommandButton(title: String(localized: "menu.view.toggleReactGrab", defaultValue: "Toggle React Grab"), shortcut: menuShortcut(for: .toggleReactGrab)) {
                if !performFocusedBrowserAction(.toggleReactGrab) {
                    NSSound.beep()
                }
            }
            splitCommandButton(title: String(localized: "menu.view.toggleDesignMode", defaultValue: "Toggle Design Mode"), shortcut: menuShortcut(for: .toggleBrowserDesignMode)) {
                if !performFocusedBrowserAction(
                    .toggleDesignMode(reason: "viewMenu")
                ) {
                    NSSound.beep()
                }
            }
            let browserFocusModeMenu = browserFocusModeMenuSnapshot
            Button(browserFocusModeMenu.title) {
                if !performFocusedBrowserAction(
                    .toggleFocusMode(reason: "viewMenu")
                ) {
                    NSSound.beep()
                }
            }
            .disabled(!browserFocusModeMenu.canToggle)
            splitCommandButton(title: String(localized: "menu.view.zoomIn", defaultValue: "Zoom In"), shortcut: menuShortcut(for: .browserZoomIn)) {
                if activeBrowserActionTarget != nil {
                    _ = performFocusedBrowserAction(.zoomIn)
                } else {
                    _ = activeTabManager.zoomInFocusedBrowserOrTextFilePreview()
                }
            }

            splitCommandButton(title: String(localized: "menu.view.zoomOut", defaultValue: "Zoom Out"), shortcut: menuShortcut(for: .browserZoomOut)) {
                if activeBrowserActionTarget != nil {
                    _ = performFocusedBrowserAction(.zoomOut)
                } else {
                    _ = activeTabManager.zoomOutFocusedBrowserOrTextFilePreview()
                }
            }

            splitCommandButton(title: String(localized: "menu.view.actualSize", defaultValue: "Actual Size"), shortcut: menuShortcut(for: .browserZoomReset)) {
                if activeBrowserActionTarget != nil {
                    _ = performFocusedBrowserAction(.resetZoom)
                } else {
                    _ = activeTabManager.resetZoomFocusedBrowserOrTextFilePreview()
                }
            }
            FilePreviewWordWrapMenu(shortcut: menuShortcut(for: .toggleFileEditorWordWrap), target: { appDelegate.shortcutFocusedSavingTextView(in: NSApp.keyWindow ?? NSApp.mainWindow) })
            Button(String(localized: "menu.view.clearBrowserHistory", defaultValue: "Clear Browser History")) {
                BrowserHistoryStore.shared.clearHistory()
            }

            Button(String(localized: "menu.view.importFromBrowser", defaultValue: "Import Browser Data…")) {
                // Defer modal presentation until after AppKit finishes menu tracking.
                DispatchQueue.main.async {
                    browserDataImportCoordinator.presentImportDialog()
                }
            }

            splitCommandButton(title: String(localized: "menu.view.nextWorkspace", defaultValue: "Next Workspace"), shortcut: menuShortcut(for: .nextSidebarTab)) {
                activeTabManager.selectNextTab()
            }

            splitCommandButton(title: String(localized: "menu.view.previousWorkspace", defaultValue: "Previous Workspace"), shortcut: menuShortcut(for: .prevSidebarTab)) {
                activeTabManager.selectPreviousTab()
            }
            splitCommandButton(title: String(localized: "shortcut.moveWorkspaceUp.label", defaultValue: "Move Workspace Up"), shortcut: menuShortcut(for: .moveWorkspaceUp)) {
                activeTabManager.moveSelectedWorkspace(by: -1)
            }
            splitCommandButton(title: String(localized: "shortcut.moveWorkspaceDown.label", defaultValue: "Move Workspace Down"), shortcut: menuShortcut(for: .moveWorkspaceDown)) {
                activeTabManager.moveSelectedWorkspace(by: 1)
            }
            splitCommandButton(title: String(localized: "menu.view.renameWorkspace", defaultValue: "Rename Workspace…"), shortcut: menuShortcut(for: .renameWorkspace)) {
                _ = AppDelegate.shared?.requestRenameWorkspaceViaCommandPalette()
            }

            splitCommandButton(title: String(localized: "menu.view.editWorkspaceDescription", defaultValue: "Edit Workspace Description…"), shortcut: menuShortcut(for: .editWorkspaceDescription)) {
                _ = AppDelegate.shared?.requestEditWorkspaceDescriptionViaCommandPalette()
            }

            splitCommandButton(title: String(localized: "command.toggleFullScreen.title", defaultValue: "Toggle Full Screen"), shortcut: menuShortcut(for: .toggleFullScreen)) {
                guard let targetWindow = NSApp.keyWindow ?? NSApp.mainWindow else { return }
                targetWindow.toggleFullScreen(nil)
            }

            Divider()

            splitCommandButton(title: String(localized: "menu.view.splitRight", defaultValue: "Split Right"), shortcut: menuShortcut(for: .splitRight)) {
                performSplitFromMenu(direction: .right)
            }

            splitCommandButton(title: String(localized: "menu.view.splitDown", defaultValue: "Split Down"), shortcut: menuShortcut(for: .splitDown)) {
                performSplitFromMenu(direction: .down)
            }

            if offersBrowserMenuItems {
                splitCommandButton(title: String(localized: "menu.view.splitBrowserRight", defaultValue: "Split Browser Right"), shortcut: menuShortcut(for: .splitBrowserRight)) {
                    performBrowserSplitFromMenu(direction: .right)
                }

                splitCommandButton(title: String(localized: "menu.view.splitBrowserDown", defaultValue: "Split Browser Down"), shortcut: menuShortcut(for: .splitBrowserDown)) {
                    performBrowserSplitFromMenu(direction: .down)
                }
            }

            paneSizingCommandButtons()
            Divider()

            splitCommandButton(title: String(localized: "menu.view.toggleCanvasLayout", defaultValue: "Toggle Canvas Layout"), shortcut: menuShortcut(for: .toggleCanvasLayout)) {
                guard let workspace = activeTabManager.selectedWorkspace else { return }
                CanvasActionExecutor(workspace: workspace).perform(.toggleLayout)
            }

            splitCommandButton(title: String(localized: "menu.view.canvasOverview", defaultValue: "Canvas Overview"), shortcut: menuShortcut(for: .canvasOverview)) {
                guard let workspace = activeTabManager.selectedWorkspace else { return }
                CanvasActionExecutor(workspace: workspace).perform(.toggleOverview)
            }

            splitCommandButton(title: String(localized: "menu.view.canvasTidy", defaultValue: "Tidy Canvas"), shortcut: menuShortcut(for: .canvasTidy)) {
                guard let workspace = activeTabManager.selectedWorkspace else { return }
                CanvasActionExecutor(workspace: workspace).perform(.alignment(.tidy))
            }

            Divider()

            // Numbered workspace selection (9 = last visible workspace row)
            ForEach(1...9, id: \.self) { number in
                // `menuShortcut(for:)` already returns `.unbound` when the action
                // carries a configured `shortcuts.when` clause, so a context-gated
                // workspace shortcut takes the no-key-equivalent branch and the
                // gated keyDown handler owns dispatch (issue #5189).
                let selectWorkspaceByNumberShortcut = menuShortcut(for: .selectWorkspaceByNumber)
                if selectWorkspaceByNumberShortcut.isUnbound || selectWorkspaceByNumberShortcut.hasChord {
                    Button(String(localized: "menu.view.workspace", defaultValue: "Workspace \(number)")) {
                        activeTabManager.selectWorkspaceByNumber(number)
                    }
                } else {
                    Button(String(localized: "menu.view.workspace", defaultValue: "Workspace \(number)")) {
                        activeTabManager.selectWorkspaceByNumber(number)
                    }
                    .keyboardShortcut(
                        KeyEquivalent(Character("\(number)")),
                        modifiers: selectWorkspaceByNumberShortcut.eventModifiers
                    )
                }
            }

            Divider()

            splitCommandButton(title: String(localized: "menu.view.jumpToUnread", defaultValue: "Jump to Latest Unread"), shortcut: menuShortcut(for: .jumpToUnread)) {
                AppDelegate.shared?.jumpToLatestUnread()
            }

            splitCommandButton(title: String(localized: "menu.view.jumpToLastPrompt", defaultValue: "Jump to Last Prompt"), shortcut: menuShortcut(for: .jumpToLastPrompt)) {
                AppDelegate.shared?.jumpToLastPromptFromUserCommand()
            }

            splitCommandButton(title: String(localized: "menu.view.showNotifications", defaultValue: "Show Notifications"), shortcut: menuShortcut(for: .showNotifications)) {
                showNotificationsPopover()
            }
        }
    }

    private func showAboutPanel() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController(
                acknowledgments: AcknowledgmentsWindowController(),
                prepareWindow: { [appDelegate] window in appDelegate.applyWindowDecorations(to: window) },
                prepareTitlebar: { [appDelegate] window in
                    appDelegate.aboutTitlebarDebugStore.applyCurrentOptions(to: window, for: .about)
                }
            )
        }
        aboutWindowController?.show()
    }

    private func applyAppearance() {
        let mode = AppearanceSettings.applyStoredMode(
            rawValue: appearanceMode,
            source: "cmuxApp.appearanceModeChanged"
        )
        if appearanceMode != mode.rawValue {
            appearanceMode = mode.rawValue
        }
    }

    private static func applyAppearance(_ mode: AppearanceMode, duringLaunch: Bool = false) {
        AppearanceSettings.applyLiveMode(
            mode,
            source: duringLaunch ? "cmuxApp.launch" : "cmuxApp.applyAppearance",
            duringLaunch: duringLaunch,
            synchronizeTerminalTheme: !duringLaunch
        )
    }

    private func updateSocketController() {
        appDelegate.reconcileSocketListenerConfiguration(
            source: "settings.automation.socketControlMode.appStorage"
        )
    }

    private func bootstrapMainWindowScene() {
        appDelegate.adoptInitialMainWindowBootstrapManager(tabManager)
        appDelegate.scheduleInitialMainWindowBootstrap(debugSource: "swiftUIBootstrap")
        appDelegate.installReloadConfigurationMenuItemAction()
        applyAppearance()
    }

    func menuShortcut(for action: KeyboardShortcutSettings.Action) -> StoredShortcut {
        let _ = keyboardShortcutSettingsObserver.revision
        return KeyboardShortcutSettings.menuShortcut(for: action)
    }

    private var notificationMenuSnapshot: NotificationMenuSnapshot {
        notificationStore.notificationMenuSnapshot
    }

    /// Whether the menus offer their browser-*creating* entries. Reads the
    /// revision so they re-evaluate when the availability gate changes.
    ///
    /// Guards creation only: New Browser Workspace and the browser splits.
    /// Commands that drive an already-open panel (Back, Reload, developer
    /// tools) stay visible because the user-level toggle leaves live panels
    /// open, and so do the zoom commands, which fall back to zooming a focused
    /// text file preview when no browser is focused (#10866).
    private var offersBrowserMenuItems: Bool {
        let _ = browserAvailabilityMenuRevision
        return BrowserAvailabilitySettings.offersBrowserAffordance(
            isEnabled: BrowserAvailabilitySettings.isEnabled()
        )
    }

    private var browserFocusModeMenuSnapshot: (title: String, canToggle: Bool) {
        let _ = browserFocusModeMenuRevision
        let panel = activeBrowserPanel
        return (
            title: panel?.isBrowserFocusModeActive == true
                ? String(localized: "menu.view.exitBrowserFocusMode", defaultValue: "Exit Browser Focus Mode")
                : String(localized: "menu.view.enterBrowserFocusMode", defaultValue: "Enter Browser Focus Mode"),
            canToggle: panel?.canToggleBrowserFocusMode == true
        )
    }

    private var activeBrowserActionTarget: BrowserActionTarget? {
        appDelegate.focusedBrowserActionTarget(
            preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
        )
    }

    private var activeBrowserPanel: BrowserPanel? {
        guard let target = activeBrowserActionTarget else { return nil }
        return appDelegate.browserPanel(resolving: target)
    }

    @discardableResult
    private func performFocusedBrowserAction(
        _ action: BrowserAction
    ) -> Bool {
        guard let target = activeBrowserActionTarget else { return false }
        return BrowserActionDispatcher(appDelegate: appDelegate)
            .perform(action, on: target)
    }

    private var activeFindIsVisible: Bool {
        if let activeBrowserPanel {
            return activeBrowserPanel.searchState != nil
        }
        return activeTabManager.isFindVisible
    }

    var activeTabManager: TabManager {
        AppDelegate.shared?.activeTabManagerForCommands(
            preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
        ) ?? tabManager
    }

    /// Whether the "New Local Workspace" File-menu item should be shown: true only
    /// when plain New Workspace in the active window would route to a remote tmux
    /// host. Reads `historyMenuCoordinator.state` so the menu re-evaluates on
    /// window-focus and workspace-selection changes: the coordinator refreshes its
    /// state when focus history changes and when a window becomes key, and a window
    /// must become key before its menu bar opens. Also reads the controller's
    /// mirror-membership, which changes when a mirror is added or removed. A workspace can
    /// start or stop being a mirror while it stays selected, and neither focus nor
    /// selection changes when that happens. The setting read keeps the menu in sync when
    /// routing is toggled while the selected mirror remains unchanged.
    private var newLocalWorkspaceMenuItemVisible: Bool {
        false
    }

    private func notificationMenuItemTitle(for notification: TerminalNotification) -> String {
        let tabTitle = appDelegate.tabTitle(for: notification.tabId)
        return MenuBarNotificationLineFormatter.menuTitle(notification: notification, tabTitle: tabTitle)
    }

    private func openNotificationFromMainMenu(_ notification: TerminalNotification) {
        _ = appDelegate.openTerminalNotification(notification)
    }

    private func performSplitFromMenu(direction: SplitDirection) {
        if AppDelegate.shared?.performSplitShortcut(direction: direction) == true {
            return
        }
        tabManager.createSplit(direction: direction)
    }

    private func performBrowserSplitFromMenu(direction: SplitDirection) {
        if activeBrowserActionTarget != nil {
            if !performFocusedBrowserAction(.split(direction)) {
                NSSound.beep()
            }
            return
        }
        if AppDelegate.shared?.performBrowserSplitShortcut(direction: direction) == true {
            return
        }
        _ = tabManager.createBrowserSplit(direction: direction)
    }

    private func selectedWorkspaceWindowMoveTargets(in manager: TabManager) -> [AppDelegate.WindowMoveTarget] {
        let referenceWindowId = AppDelegate.shared?.windowId(for: manager)
        return AppDelegate.shared?.windowMoveTargets(referenceWindowId: referenceWindowId) ?? []
    }

    private func toggleSelectedWorkspacePinned(in manager: TabManager) {
        if !WorkspacePinCommands.toggleSelectedWorkspace(in: manager) {
            NSSound.beep()
        }
    }

    private func clearSelectedWorkspaceCustomName(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace else { return }
        manager.clearCustomTitle(tabId: workspace.id)
    }

    private func moveSelectedWorkspaceToTop(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace else { return }
        manager.moveTabsToTop([workspace.id])
        manager.selectWorkspace(workspace)
    }

    private func moveSelectedWorkspace(in manager: TabManager, toWindow windowId: UUID) {
        guard let workspace = manager.selectedWorkspace else { return }
        _ = AppDelegate.shared?.moveWorkspaceToWindow(workspaceId: workspace.id, windowId: windowId, focus: true)
    }

    private func moveSelectedWorkspaceToNewWindow(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace else { return }
        _ = AppDelegate.shared?.moveWorkspaceToNewWindow(workspaceId: workspace.id, focus: true)
    }

    private func closeWorkspaceIds(
        _ workspaceIds: [UUID],
        in manager: TabManager,
        allowPinned: Bool
    ) {
        manager.closeWorkspacesWithConfirmation(workspaceIds, allowPinned: allowPinned)
    }

    private func closeOtherSelectedWorkspacePeers(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace else { return }
        let workspaceIds = manager.tabs.compactMap { $0.id == workspace.id ? nil : $0.id }
        closeWorkspaceIds(workspaceIds, in: manager, allowPinned: true)
    }

    private func closeSelectedWorkspacesBelow(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace,
              let anchorIndex = selectedWorkspaceIndex(in: manager, workspaceId: workspace.id) else { return }
        let workspaceIds = manager.tabs.suffix(from: anchorIndex + 1).map(\.id)
        closeWorkspaceIds(workspaceIds, in: manager, allowPinned: true)
    }

    private func closeSelectedWorkspacesAbove(in manager: TabManager) {
        guard let workspace = manager.selectedWorkspace,
              let anchorIndex = selectedWorkspaceIndex(in: manager, workspaceId: workspace.id) else { return }
        let workspaceIds = manager.tabs.prefix(upTo: anchorIndex).map(\.id)
        closeWorkspaceIds(workspaceIds, in: manager, allowPinned: true)
    }

    private func selectedWorkspaceCanMarkRead(in manager: TabManager) -> Bool {
        guard let workspaceId = manager.selectedWorkspace?.id else { return false }
        return notificationStore.canMarkWorkspaceRead(forTabIds: [workspaceId])
    }

    private func selectedWorkspaceCanMarkUnread(in manager: TabManager) -> Bool {
        guard let workspaceId = manager.selectedWorkspace?.id else { return false }
        return notificationStore.canMarkWorkspaceUnread(forTabIds: [workspaceId])
    }

    private func markSelectedWorkspaceRead(in manager: TabManager) {
        guard let workspaceId = manager.selectedWorkspace?.id else { return }
        notificationStore.markRead(forTabId: workspaceId)
    }

    private func markSelectedWorkspaceUnread(in manager: TabManager) {
        guard let workspaceId = manager.selectedWorkspace?.id else { return }
        notificationStore.markUnread(forTabId: workspaceId)
    }

    @ViewBuilder
    private func workspaceCommandMenuContent(manager: TabManager) -> some View {
        let workspace = manager.selectedWorkspace
        let workspaceIndex = workspace.flatMap { selectedWorkspaceIndex(in: manager, workspaceId: $0.id) }
        let windowMoveTargets = selectedWorkspaceWindowMoveTargets(in: manager)
        let pinState = WorkspacePinCommands.selectedWorkspacePinState(in: manager)

        Button(WorkspacePinCommands.selectedWorkspaceMenuLabel(in: manager, pinState: pinState)) {
            toggleSelectedWorkspacePinned(in: manager)
        }
        .disabled(pinState == nil)

        Button(String(localized: "menu.view.renameWorkspace", defaultValue: "Rename Workspace…")) {
            _ = AppDelegate.shared?.requestRenameWorkspaceViaCommandPalette()
        }
        .disabled(workspace == nil)

        Button(String(localized: "menu.view.editWorkspaceDescription", defaultValue: "Edit Workspace Description…")) {
            _ = AppDelegate.shared?.requestEditWorkspaceDescriptionViaCommandPalette()
        }
        .disabled(workspace == nil)

        if workspace?.hasCustomTitle == true {
            Button(String(localized: "contextMenu.removeCustomWorkspaceName", defaultValue: "Remove Custom Workspace Name")) {
                clearSelectedWorkspaceCustomName(in: manager)
            }
        }

        Divider()

        Button(String(localized: "contextMenu.moveUp", defaultValue: "Move Up")) {
            manager.moveSelectedWorkspace(by: -1)
        }
        .disabled(workspaceIndex == nil || workspaceIndex == 0)

        Button(String(localized: "contextMenu.moveDown", defaultValue: "Move Down")) {
            manager.moveSelectedWorkspace(by: 1)
        }
        .disabled(workspaceIndex == nil || workspaceIndex == manager.tabs.count - 1)

        Button(String(localized: "contextMenu.moveToTop", defaultValue: "Move to Top")) {
            moveSelectedWorkspaceToTop(in: manager)
        }
        .disabled(workspace == nil || workspaceIndex == 0)

        Menu(String(localized: "contextMenu.moveWorkspaceToWindow", defaultValue: "Move Workspace to Window")) {
            Button(String(localized: "contextMenu.newWindow", defaultValue: "New Window")) {
                moveSelectedWorkspaceToNewWindow(in: manager)
            }
            .disabled(workspace == nil)

            if !windowMoveTargets.isEmpty {
                Divider()
            }

            ForEach(windowMoveTargets) { target in
                Button(target.label) {
                    moveSelectedWorkspace(in: manager, toWindow: target.windowId)
                }
                .disabled(target.isCurrentWindow || workspace == nil)
            }
        }
        .disabled(workspace == nil)

        Divider()

        Button(String(localized: "menu.file.closeWorkspace", defaultValue: "Close Workspace")) {
            manager.closeCurrentWorkspaceWithConfirmation()
        }
        .disabled(workspace == nil)

        Button(String(localized: "contextMenu.closeOtherWorkspaces", defaultValue: "Close Other Workspaces")) {
            closeOtherSelectedWorkspacePeers(in: manager)
        }
        .disabled(workspace == nil || manager.tabs.count <= 1)

        Button(String(localized: "contextMenu.closeWorkspacesBelow", defaultValue: "Close Workspaces Below")) {
            closeSelectedWorkspacesBelow(in: manager)
        }
        .disabled(workspaceIndex == nil || workspaceIndex == manager.tabs.count - 1)

        Button(String(localized: "contextMenu.closeWorkspacesAbove", defaultValue: "Close Workspaces Above")) {
            closeSelectedWorkspacesAbove(in: manager)
        }
        .disabled(workspaceIndex == nil || workspaceIndex == 0)

        Divider()

        Button(String(localized: "contextMenu.markWorkspaceRead", defaultValue: "Mark Workspace as Read")) {
            markSelectedWorkspaceRead(in: manager)
        }
        .disabled(!selectedWorkspaceCanMarkRead(in: manager))

        Button(String(localized: "contextMenu.markWorkspaceUnread", defaultValue: "Mark Workspace as Unread")) {
            markSelectedWorkspaceUnread(in: manager)
        }
        .disabled(!selectedWorkspaceCanMarkUnread(in: manager))
    }

    @ViewBuilder
    func splitCommandButton(title: String, shortcut: StoredShortcut, action: @escaping () -> Void) -> some View {
        if let key = shortcut.keyEquivalent {
            Button(title, action: action)
                .keyboardShortcut(key, modifiers: shortcut.eventModifiers)
        } else {
            Button(title, action: action)
        }
    }

    private func dispatchReloadConfigurationMenuCommand() {
        NSApp.sendAction(
            #selector(AppDelegate.reloadConfigurationMenuItem(_:)),
            to: appDelegate,
            from: nil
        )
    }

    private func closePanelOrWindow() {
        let window = NSApp.keyWindow ?? NSApp.mainWindow
        if let window, cmuxWindowShouldOwnCloseShortcut(window) { window.performClose(nil); return }
        if appDelegate.closeFocusedDockPanelForCommand(preferredWindow: window) { return }
        activeTabManager.closeCurrentPanelWithConfirmation()
    }

    private func closeOtherTabsInFocusedPane() {
        if let dock = appDelegate.focusedDockStoreForShortcut(
            preferredWindow: NSApp.keyWindow ?? NSApp.mainWindow
        ) {
            _ = dock.performShortcutCommand(.closeOtherTabsInPane)
            return
        }
        activeTabManager.closeOtherTabsInFocusedPaneWithConfirmation()
    }

    private func closeTabOrWindow() {
        activeTabManager.closeCurrentTabWithConfirmation()
    }

    private func showNotificationsPopover() {
        AppDelegate.shared?.toggleNotificationsPopover(animated: false)
    }

}

private struct MainWindowBootstrapView: View {
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .background(WindowAccessor { window in
                window.identifier = NSUserInterfaceItemIdentifier("cmux.bootstrap")
                window.isRestorable = false
                window.orderOut(nil)
                let windowIdentifier = ObjectIdentifier(window)
                Task { @MainActor in
                    guard let window = NSApp.windows.first(where: { ObjectIdentifier($0) == windowIdentifier }) else {
                        return
                    }
                    window.orderOut(nil)
                    window.close()
                }
            })
    }
}
private let cmuxAuxiliaryWindowIdentifiers: Set<String> = [
    "cmux.newMachine",
    "cmux.settings",
    "cmux.about",
    "cmux.cloud.welcome",
    "cmux.licenses",
    "cmux.browser-popup",
    "cmux.browserProfilePopoverDebug",
    "cmux.configEditor",
    "cmux.computerUse.onboarding",
    "cmux.defaultTerminalRegistrationError",
    "cmux.featureFlags",
    "cmux.feedButtonStyleDebug",
    "cmux.feedPreview",
    "cmux.feedTextEditorDebug",
    "cmux.fileExplorerStyleDebug",
    "cmux.folderDragIcon",
    "cmux.pdfPreviewChromeDebug",
    "cmux.proBadgeDebug",
    "cmux.recentlyClosedHistory",
    "cmux.tabBarBackdropLab",
    "cmux.taskManager",
    "cmux.aboutTitlebarDebug",
    "cmux.debugWindowControls",
    "cmux.browserImportHintDebug",
    "cmux.extensionSidebarInspector",
    "cmux.sidebarDebug",
    "cmux.menubarDebug",
    "cmux.spinnerGallery",
    "cmux.cloudTreeStyleGallery",
    "cmux.cloudSidebarDebugLab",
    "cmux.backgroundDebug",
    "cmux.startupAppearanceDebug",
    "cmux.bonsplitTabBarDebug",
    "cmux.titlebarLayoutDebug",
    "cmux.devWindowDisplay",
    "cmux.mobilePairingWindow",
    "cmux.sidebarFooterIconBalanceDebug",
    "cmux.cloudPaneCreationFailure.card",
    "cmux.cloudCreateTeam",
    "cmux.sudo.approval",
]

/// Returns whether the given window should handle the standard close shortcut
/// as a standalone auxiliary window instead of routing it through workspace or
/// panel-close behavior.
func cmuxWindowShouldOwnCloseShortcut(_ window: NSWindow?) -> Bool {
    guard let identifier = window?.identifier?.rawValue else { return false }
    return cmuxAuxiliaryWindowIdentifiers.contains(identifier)
}

private enum DebugWindowConfigSnapshot {
    static func copyCombinedToPasteboard(defaults: UserDefaults = .standard) {
        GhosttyApp.terminalPasteboard.writeString(
            combinedPayload(defaults: defaults),
            to: .general
        )
    }

    static func combinedPayload(defaults: UserDefaults = .standard) -> String {
        let sidebarPayload = """
        sidebarPreset=\(stringValue(defaults, key: "sidebarPreset", fallback: SidebarPresetOption.nativeSidebar.rawValue))
        sidebarMaterial=\(stringValue(defaults, key: "sidebarMaterial", fallback: SidebarMaterialOption.sidebar.rawValue))
        sidebarBlendMode=\(stringValue(defaults, key: "sidebarBlendMode", fallback: SidebarBlendModeOption.withinWindow.rawValue))
        sidebarState=\(stringValue(defaults, key: "sidebarState", fallback: SidebarStateOption.followWindow.rawValue))
        sidebarBlurOpacity=\(String(format: "%.2f", doubleValue(defaults, key: "sidebarBlurOpacity", fallback: 1.0)))
        sidebarTintHex=\(stringValue(defaults, key: "sidebarTintHex", fallback: "#000000"))
        sidebarTintHexLight=\(stringValue(defaults, key: "sidebarTintHexLight", fallback: "(nil)"))
        sidebarTintHexDark=\(stringValue(defaults, key: "sidebarTintHexDark", fallback: "(nil)"))
        sidebarTintOpacity=\(String(format: "%.2f", doubleValue(defaults, key: "sidebarTintOpacity", fallback: 0.18)))
        sidebarCornerRadius=\(String(format: "%.1f", doubleValue(defaults, key: "sidebarCornerRadius", fallback: 0.0)))
        sidebarBranchVerticalLayout=\(boolValue(defaults, key: SidebarCatalogSection().branchVerticalLayout.userDefaultsKey, fallback: SidebarCatalogSection().branchVerticalLayout.defaultValue))
        sidebarBranchDirectoryStacked=\(boolValue(defaults, key: SidebarCatalogSection().stackBranchDirectory.userDefaultsKey, fallback: SidebarCatalogSection().stackBranchDirectory.defaultValue))
        sidebarPathLastSegmentOnly=\(boolValue(defaults, key: SidebarCatalogSection().pathLastSegmentOnly.userDefaultsKey, fallback: SidebarCatalogSection().pathLastSegmentOnly.defaultValue))
        sidebarActiveTabIndicatorStyle=\(stringValue(defaults, key: WorkspaceColorsCatalogSection().indicatorStyle.userDefaultsKey, fallback: WorkspaceColorsCatalogSection().indicatorStyle.defaultValue.rawValue))
        sidebarDevBuildBannerVisible=\(boolValue(defaults, key: DevBuildBannerDebugSettings.sidebarBannerVisibleKey, fallback: DevBuildBannerDebugSettings.defaultShowSidebarBanner))
        sidebarMinimumWidth=\(String(format: "%.1f", SessionPersistencePolicy.resolvedMinimumSidebarWidth(defaults: defaults)))
        """

        let backgroundPayload = """
        bgGlassEnabled=\(boolValue(defaults, key: "bgGlassEnabled", fallback: false))
        bgGlassMaterial=\(stringValue(defaults, key: "bgGlassMaterial", fallback: "hudWindow"))
        bgGlassTintHex=\(stringValue(defaults, key: "bgGlassTintHex", fallback: "#000000"))
        bgGlassTintOpacity=\(String(format: "%.2f", doubleValue(defaults, key: "bgGlassTintOpacity", fallback: 0.03)))
        """

        let menuBarPayload = MenuBarIconDebugSettings.copyPayload(defaults: defaults)
        let browserDevToolsPayload = BrowserDevToolsButtonDebugSettings.copyPayload(defaults: defaults)

        return """
        # Sidebar Debug
        \(sidebarPayload)

        # Background Debug
        \(backgroundPayload)

        # Menu Bar Extra Debug
        \(menuBarPayload)

        # Browser DevTools Button
        \(browserDevToolsPayload)
        """
    }

    private static func stringValue(_ defaults: UserDefaults, key: String, fallback: String) -> String {
        defaults.string(forKey: key) ?? fallback
    }

    private static func doubleValue(_ defaults: UserDefaults, key: String, fallback: Double) -> Double {
        if let value = defaults.object(forKey: key) as? NSNumber {
            return value.doubleValue
        }
        if let text = defaults.string(forKey: key), let parsed = Double(text) {
            return parsed
        }
        return fallback
    }

    private static func boolValue(_ defaults: UserDefaults, key: String, fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }
}

#if DEBUG
private final class DebugWindowControlsWindowController: ReleasingWindowController {
    static let shared = DebugWindowControlsWindowController()

    override func makeWindow() -> NSWindow {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Debug Window Controls"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.identifier = NSUserInterfaceItemIdentifier("cmux.debugWindowControls")
        window.center()
        window.contentView = NSHostingView(rootView: DebugWindowControlsView())
        AppDelegate.shared?.applyWindowDecorations(to: window)
        return window
    }

    func show() {
        showManagedWindow()
    }
}

private struct DebugWindowControlsView: View {
    @Environment(\.cmuxAccentColor) private var cmuxAccent
    @AppStorage(WorkspaceColorsCatalogSection().indicatorStyle.userDefaultsKey)
    private var sidebarActiveTabIndicatorStyle = WorkspaceColorsCatalogSection().indicatorStyle.defaultValue.rawValue
    @AppStorage(BrowserDevToolsButtonDebugSettings.iconNameKey) private var browserDevToolsIconNameRaw = BrowserDevToolsButtonDebugSettings.defaultIcon.rawValue
    @AppStorage(BrowserDevToolsButtonDebugSettings.iconColorKey) private var browserDevToolsIconColorRaw = BrowserDevToolsButtonDebugSettings.defaultColor.rawValue

    private var selectedDevToolsIconOption: BrowserDevToolsIconOption {
        BrowserDevToolsIconOption(rawValue: browserDevToolsIconNameRaw) ?? BrowserDevToolsButtonDebugSettings.defaultIcon
    }

    private var selectedDevToolsColorOption: BrowserDevToolsIconColorOption {
        BrowserDevToolsIconColorOption(rawValue: browserDevToolsIconColorRaw) ?? BrowserDevToolsButtonDebugSettings.defaultColor
    }

    private var selectedSidebarActiveTabIndicatorStyle: WorkspaceIndicatorStyle {
        WorkspaceIndicatorStyle.decodeFromUserDefaults(sidebarActiveTabIndicatorStyle)
            ?? WorkspaceColorsCatalogSection().indicatorStyle.defaultValue
    }

    private var sidebarIndicatorStyleSelection: Binding<String> {
        Binding(
            get: { selectedSidebarActiveTabIndicatorStyle.rawValue },
            set: { sidebarActiveTabIndicatorStyle = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Debug Window Controls")
                    .cmuxFont(.headline)

                GroupBox("Active Workspace Indicator") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Style", selection: sidebarIndicatorStyleSelection) {
                            ForEach(WorkspaceIndicatorStyle.allCases, id: \.self) { style in
                                Text(style.displayName).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.menu)

                        Button("Reset Indicator Style") {
                            sidebarActiveTabIndicatorStyle = WorkspaceColorsCatalogSection().indicatorStyle.defaultValue.rawValue
                        }
                    }
                    .padding(.top, 2)
                }

                GroupBox("Browser DevTools Button") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Icon")
                            Picker("Icon", selection: $browserDevToolsIconNameRaw) {
                                ForEach(BrowserDevToolsIconOption.allCases) { option in
                                    Text(option.title).tag(option.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text("Color")
                            Picker("Color", selection: $browserDevToolsIconColorRaw) {
                                ForEach(BrowserDevToolsIconColorOption.allCases) { option in
                                    Text(option.title).tag(option.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text("Preview")
                            Spacer()
                            Image(systemName: selectedDevToolsIconOption.rawValue)
                                .cmuxFont(size: 12, weight: .medium)
                                .foregroundStyle(selectedDevToolsColorOption.color(accent: cmuxAccent))
                        }

                        HStack(spacing: 12) {
                            Button("Reset Button") {
                                resetBrowserDevToolsButton()
                            }
                            Button("Copy Button Config") {
                                copyBrowserDevToolsButtonConfig()
                            }
                        }
                    }
                    .padding(.top, 2)
                }

                GroupBox("Copy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Copy All Debug Config") {
                            DebugWindowConfigSnapshot.copyCombinedToPasteboard()
                        }
                        Text("Copies sidebar, background, menu bar, and browser devtools settings as one payload.")
                            .cmuxFont(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func resetBrowserDevToolsButton() {
        browserDevToolsIconNameRaw = BrowserDevToolsButtonDebugSettings.defaultIcon.rawValue
        browserDevToolsIconColorRaw = BrowserDevToolsButtonDebugSettings.defaultColor.rawValue
    }

    private func copyBrowserDevToolsButtonConfig() {
        let payload = BrowserDevToolsButtonDebugSettings.copyPayload(defaults: .standard)
        GhosttyApp.terminalPasteboard.writeString(
            payload,
            to: .general
        )
    }
}
#endif

enum AppIconMode: String, CaseIterable, Identifiable {
    case automatic
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return String(localized: "appIcon.automatic", defaultValue: "Automatic")
        case .light: return String(localized: "appIcon.light", defaultValue: "Light")
        case .dark: return String(localized: "appIcon.dark", defaultValue: "Dark")
        }
    }

    var imageName: String? {
        switch self {
        case .automatic: return nil
        case .light: return "AppIconLight"
        case .dark: return "AppIconDark"
        }
    }
}

enum AppIconLaunchState {
    private static let lock = NSLock()
    private static var didFinishLaunching = false

    static func markDidFinishLaunching() {
        lock.lock()
        defer { lock.unlock() }
        didFinishLaunching = true
    }

    static func isApplicationFinishedLaunching() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let hasFinishedLaunching = didFinishLaunching
        return hasFinishedLaunching
    }
}

enum AppIconSettings {
    static let modeKey = "appIconMode"
    static let defaultMode: AppIconMode = .automatic
    private static let dockTileIconDidChangeNotification = Notification.Name("com.cmuxterm.appIconDidChange")
    private static var liveEnvironmentProvider: () -> Environment = { .live() }

    private static func isRunningUnderXCTest(_ env: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        if env["CMUX_TEST_PROCESS"] == "1" { return true }
        if env["XCTestConfigurationFilePath"] != nil { return true }
        if env["XCTestBundlePath"] != nil { return true }
        if env["XCTestSessionIdentifier"] != nil { return true }
        if env["XCInjectBundle"] != nil { return true }
        if env["XCInjectBundleInto"] != nil { return true }
        if env["DYLD_INSERT_LIBRARIES"]?.contains("libXCTest") == true { return true }
        if env.keys.contains(where: { $0.hasPrefix("CMUX_UI_TEST_") }) { return true }
        return false
    }

    struct Environment {
        let isApplicationFinishedLaunching: () -> Bool
        let imageForMode: (AppIconMode) -> NSImage?
        let setApplicationIconImage: (NSImage) -> Void
        let startAppearanceObservation: () -> Void
        let stopAppearanceObservation: () -> Void
        let notifyDockTilePlugin: () -> Void

        static func live() -> Self {
            Self(
                isApplicationFinishedLaunching: {
                    AppIconLaunchState.isApplicationFinishedLaunching()
                },
                imageForMode: { mode in
                    guard let imageName = mode.imageName else { return nil }
                    return NSImage(named: imageName)
                },
                setApplicationIconImage: { icon in
                    NSApplication.shared.applicationIconImage = icon
                },
                startAppearanceObservation: {
                    AppIconAppearanceObserver.shared.startObserving()
                },
                stopAppearanceObservation: {
                    AppIconAppearanceObserver.shared.stopObserving()
                },
                notifyDockTilePlugin: {
                    guard !AppIconSettings.isRunningUnderXCTest() else { return }
                    DistributedNotificationCenter.default().postNotificationName(
                        AppIconSettings.dockTileIconDidChangeNotification,
                        object: nil,
                        userInfo: nil,
                        deliverImmediately: true
                    )
                }
            )
        }
    }

    static func resolvedMode(defaults: UserDefaults = .standard) -> AppIconMode {
        guard let raw = defaults.string(forKey: modeKey),
              let mode = AppIconMode(rawValue: raw) else {
            return defaultMode
        }
        return mode
    }

    static func applyIcon(_ mode: AppIconMode, environment: Environment? = nil) {
        let environment = environment ?? liveEnvironmentProvider()
        // Tahoe can crash or wedge when app icon work runs during App.init(),
        // so leave settings replay to update defaults only and let AppDelegate
        // apply the resolved icon once didFinishLaunching begins.
        guard environment.isApplicationFinishedLaunching() else { return }

        switch mode {
        case .automatic:
            environment.startAppearanceObservation()
        case .light:
            environment.stopAppearanceObservation()
            guard let icon = environment.imageForMode(.light) else { return }
            environment.setApplicationIconImage(icon)
        case .dark:
            environment.stopAppearanceObservation()
            guard let icon = environment.imageForMode(.dark) else { return }
            environment.setApplicationIconImage(icon)
        }

        environment.notifyDockTilePlugin()
    }

    static func setLiveEnvironmentProviderForTesting(_ provider: @escaping () -> Environment) {
        liveEnvironmentProvider = provider
    }

    static func resetLiveEnvironmentProviderForTesting() {
        liveEnvironmentProvider = { .live() }
    }
}

final class AppIconAppearanceObserver: NSObject {
    struct Environment {
        let isApplicationFinishedLaunching: () -> Bool
        let startEffectiveAppearanceObservation: (@escaping () -> Void) -> EffectiveAppearanceObservation?
        let addDidFinishLaunchingObserver: (@escaping () -> Void) -> NSObjectProtocol
        let removeObserver: (NSObjectProtocol) -> Void
        let currentAppearanceIsDark: () -> Bool?
        let imageForName: (String) -> NSImage?
        let setApplicationIconImage: (NSImage) -> Void

        static func live() -> Self {
            Self(
                isApplicationFinishedLaunching: {
                    AppIconLaunchState.isApplicationFinishedLaunching()
                },
                startEffectiveAppearanceObservation: { handler in
                    guard let app = NSApp else { return nil }
                    return app.observe(\.effectiveAppearance, options: []) { _, _ in
                        DispatchQueue.main.async {
                            handler()
                        }
                    }
                },
                addDidFinishLaunchingObserver: { handler in
                    NotificationCenter.default.addObserver(
                        forName: NSApplication.didFinishLaunchingNotification,
                        object: nil,
                        queue: .main
                    ) { _ in
                        handler()
                    }
                },
                removeObserver: { observer in
                    NotificationCenter.default.removeObserver(observer)
                },
                currentAppearanceIsDark: {
                    guard let app = NSApp else { return nil }
                    return app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                },
                imageForName: { imageName in
                    NSImage(named: imageName)
                },
                setApplicationIconImage: { icon in
                    NSApplication.shared.applicationIconImage = icon
                }
            )
        }
    }

    static let shared = AppIconAppearanceObserver()
    private let environment: Environment
    private var observation: EffectiveAppearanceObservation?
    private var launchObserver: NSObjectProtocol?
    private var hasDeferredStartPending = false
    private var lastAppliedImageName: String?

    init(environment: Environment = .live()) {
        self.environment = environment
        super.init()
    }
    func startObserving() {
        // Tahoe crashes if effectiveAppearance is touched during App.init(),
        // so defer the first automatic-icon apply until launch completes.
        if !environment.isApplicationFinishedLaunching() {
            deferStartUntilLaunchIfNeeded()
            return
        }

        cancelDeferredStart()
        applyIconForCurrentAppearance()
        guard observation == nil else { return }
        observation = environment.startEffectiveAppearanceObservation { [weak self] in
            guard let self, self.observation != nil else { return }
            self.applyIconForCurrentAppearance()
        }
    }

    func stopObserving() {
        observation?.invalidate()
        observation = nil
        lastAppliedImageName = nil
        cancelDeferredStart()
    }
    private func deferStartUntilLaunchIfNeeded() {
        hasDeferredStartPending = true
        guard launchObserver == nil else { return }
        launchObserver = environment.addDidFinishLaunchingObserver { [weak self] in
            guard let self, self.hasDeferredStartPending else { return }
            self.cancelDeferredStart()
            self.startObserving()
        }
    }

    private func cancelDeferredStart() {
        hasDeferredStartPending = false
        guard let launchObserver else { return }
        environment.removeObserver(launchObserver)
        self.launchObserver = nil
    }
    private func applyIconForCurrentAppearance() {
        guard environment.isApplicationFinishedLaunching() else { return }
        guard let isDark = environment.currentAppearanceIsDark() else { return }
        let imageName = isDark ? "AppIconDark" : "AppIconLight"
        guard imageName != lastAppliedImageName,
              let icon = environment.imageForName(imageName) else { return }
        environment.setApplicationIconImage(icon)
        lastAppliedImageName = imageName
    }
}

@MainActor
func openCmuxSettingsFileInEditor() {
    let url = KeyboardShortcutSettings.settingsFileStore.settingsFileURLForEditing()
    PreferredEditorService(defaults: .standard).open(url)
}
