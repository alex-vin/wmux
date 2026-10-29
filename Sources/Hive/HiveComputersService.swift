import CmuxHive
import CmuxSettingsUI
import CmuxSurfaceCatalogModel
import Foundation

@MainActor
final class HiveComputersService {
    static let didChangeNotification = Notification.Name("cmux.computers.pairingsDidChange")

    private let registry: DeviceSurfaceProviderRegistry
    private let openSidebar: @MainActor (SurfaceDeviceInstanceID) -> RightSidebarRemoteApplyResult?
    private let fixedSelfInstance: SurfaceDeviceInstanceID?

    init(
        registry: DeviceSurfaceProviderRegistry,
        selfInstance: SurfaceDeviceInstanceID? = nil,
        openSidebar: @escaping @MainActor (SurfaceDeviceInstanceID) -> RightSidebarRemoteApplyResult?
    ) {
        self.registry = registry
        self.fixedSelfInstance = selfInstance
        self.openSidebar = openSidebar
    }

    var pairedComputers: [HivePairedComputer] {
        []
    }

    func configure(auth: Any? = nil) {}

    func isPaired(_ instance: SurfaceDeviceInstanceID) -> Bool {
        false
    }

    func authorization(for instance: SurfaceDeviceInstanceID, route: Any? = nil) -> Any? {
        nil
    }

    func updates() -> AsyncStream<ComputersSettingsSnapshot> {
        AsyncStream { continuation in
            continuation.yield(self.snapshot())
            continuation.finish()
        }
    }

    func refresh() async {}

    func pair(_ input: String) async -> String? {
        nil
    }

    func unpair(_ id: String) async {}

    func open(_ id: String) async {}

    private func snapshot() -> ComputersSettingsSnapshot {
        ComputersSettingsSnapshot(
            computers: [],
            isSignedIn: false,
            error: nil,
            discoveryEnabled: false,
            incomingAccessEnabled: false,
            unavailableMessage: nil
        )
    }
}
