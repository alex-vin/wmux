import WmuxCloud
import WmuxSurfaceCatalogModel
import Foundation

extension WmuxTuiSurfaceProvider {
    func noteAccessLost(_ loss: CloudMachineAccessLoss = .forbidden) {}
    func noteAccessConfirmed() {}
}
