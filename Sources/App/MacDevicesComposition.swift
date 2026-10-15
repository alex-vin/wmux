import CmuxCloud
import CmuxSettings
import CmuxSettingsUI
import CmuxSurfaceCatalogModel
import AppKit
import Foundation

/// The executable's construction boundary for device preferences, discovery, and Settings actions.
@MainActor
struct MacDevicesComposition {
    let defaultsStore: UserDefaultsSettingsStore
    let registry: DeviceSurfaceProviderRegistry
    let computers: HiveComputersService

    init(defaults: UserDefaults, catalog: SettingCatalog) {
        let store = UserDefaultsSettingsStore(defaults: defaults, migrating: catalog.all)
        let keys = catalog.devices
        let policy = ManagedDevicePolicy(defaults: defaults)
        let access = DevicesAccessCoordinator(
            read: { preference in
                store.initialValue(for: preference == .discovery ? keys.discoveryEnabled : keys.incomingAccessEnabled)
            },
            write: { preference, enabled in
                await store.set(enabled, for: preference == .discovery ? keys.discoveryEnabled : keys.incomingAccessEnabled)
            },
            canChange: { preference in
                DevicesFeature.isAvailable(defaults: defaults, policy: policy)
                    && !(preference == .discovery ? policy.isDeviceDiscoveryDisabled : policy.isIncomingDeviceAccessDisabled)
            },
            confirmIncomingAccess: {
                await DeviceDiscoverabilityConfirmation().confirm(in: NSApp.keyWindow ?? NSApp.mainWindow)
            }
        )
        let preferences = DevicesPreferencesModel(store: store, access: access)
        preferences.start()
        let registry = DeviceSurfaceProviderRegistry(
            preferences: preferences,
            // Link events share the transport journal, so one JSONL file holds
            // the dial, the admission verdict, and the row's resulting state.
            diagnostics: DeviceLinkDiagnostics(journal: MobileHostIrxRuntime.journal),
            makeAutomaticClient: { identity, teamID in
                MobileHostIrxRuntime.shared.makeDeviceClient(identity: identity, teamID: teamID)
            },
            allowsAutomaticConnections: {
                DevicesFeature.isEnabled && ManagedIrohNetworkingPolicy.isEnabled
            }
        )
        let computers = HiveComputersService(registry: registry, openSidebar: { instance in
            AppDelegate.shared?.openDevicesSidebarAndReveal(instance: instance, registry: registry)
        })
        self.defaultsStore = store
        self.registry = registry
        self.computers = computers
    }
}
