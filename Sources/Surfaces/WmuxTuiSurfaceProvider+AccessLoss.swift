import CmuxCloud
import CmuxSurfaceCatalogModel
import Foundation

extension CmuxTuiSurfaceProvider {
    func noteAccessLost(_ loss: CloudMachineAccessLoss = .forbidden) {}
    func noteAccessConfirmed() {}
}
