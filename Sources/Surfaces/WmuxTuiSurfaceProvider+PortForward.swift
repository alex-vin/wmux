import CmuxSurfaceCatalogModel
import Foundation

extension CmuxTuiSurfaceProvider {
    func refreshCloudBrowserRoutes() {}

    func materializeBrowserPane(
        _ resource: SurfaceResource,
        at destination: SurfaceDestination,
        focus: Bool
    ) async throws -> (workspaceID: UUID, panelID: UUID) {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }

    func configureBrowser(
        _ browser: BrowserPanel,
        url: URL,
        resourceID: SurfaceResourceID? = nil,
        request: URLRequest? = nil,
        preserveCurrentNavigation: Bool = false
    ) -> Bool {
        false
    }

    func showPortUnavailable(_ message: String, resourceID: SurfaceResourceID, browser: BrowserPanel) {}

    func accessModel(
        port: Int,
        address: String,
        targetHost: String? = nil,
        scheme: String? = nil,
        preservesRemoteHost: Bool = false
    ) -> CloudPortAccessModel {
        CloudPortAccessModel()
    }

    func sshServiceURL(forForwardListener url: URL) -> URL? { nil }

    func restartSSHForward(port: Int) {}

    func settleRestoredPortPanes(scannedPorts: [Int]) {}

    func reprojectRestoredBrowserPanes(generation: UInt64, resourceIDs: Set<SurfaceResourceID>? = nil) {}

    func portLinkURL(port: Int) async throws -> String {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }

    func localPortURL(port: Int) async throws -> String? { nil }

    func controlPlanePreviewURL(port: Int) async throws -> URL {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }

    func cloudLoopbackBrowserURL(for resource: SurfaceResource) -> URL? { nil }

    func cloudBrowserOriginURL(for resource: SurfaceResource, restoring browser: BrowserPanel? = nil) -> URL? { nil }
}
