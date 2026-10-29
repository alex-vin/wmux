import CmuxCloud
import CmuxSurfaceCatalogModel
import Foundation

extension CmuxTuiSurfaceProvider {
    func materializeManualMirrorTerminal(
        _ resource: SurfaceResource,
        remoteTabID: String? = nil,
        at destination: SurfaceDestination,
        focus: Bool,
        adopting reservation: CloudTerminalPaneReservation? = nil
    ) async throws -> CloudManualMirrorMaterialization {
        throw SurfaceCatalogError.unsupported("cloud disabled")
    }

    func beginAttachHandshake(for reservation: CloudTerminalPaneReservation) {}

    func resolveManualMirrorSessions(
        _ sessions: [CloudTuiManualMirrorSession],
        socketPath: String,
        link: CloudMachineLink
    ) async -> [String: CloudTuiSurfaceIDResolution] {
        [:]
    }

    func attachReservedTerminalPane(
        _ reservation: CloudTerminalPaneReservation,
        resource: SurfaceResource,
        remoteTabID: String?
    ) {}
}
