import WmuxSurfaceCatalogModel
import Foundation

/// A committed terminal retained until the canonical graph reaches its receipt.
struct PendingRemoteCreation {
    var resource: SurfaceResource
    var receipt: CloudVMCursor?
    let tabID: String?
    var machine: SurfaceMachineID { resource.machine }
}
