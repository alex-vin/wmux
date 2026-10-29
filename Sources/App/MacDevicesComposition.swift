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
        let registry = DeviceSurfaceProviderRegistry()
        let computers = HiveComputersService(registry: registry, openSidebar: { instance in
            AppDelegate.shared?.openDevicesSidebarAndReveal(instance: instance, registry: registry)
        })
        self.defaultsStore = store
        self.registry = registry
        self.computers = computers
    }
}
