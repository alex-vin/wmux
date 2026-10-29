import CmuxSettingsUI
import Foundation

/// Cloud Settings routes through pure local stubs in pure local mode.
extension HostSettingsActions {
    var isCloudMachinesAvailable: Bool {
        false
    }

    var isCloudMachinesEnabled: Bool {
        false
    }

    var cloudMachinesActivationState: CloudMachinesActivationState {
        .unavailable
    }

    func enableCloudMachines() {}

    func cancelCloudMachinesActivation() {}

    func retryCloudMachinesActivation() {}

    func disableCloudMachines() {}

    func cloudMachinesActivationUpdates() -> AsyncStream<CloudMachinesActivationState> {
        AsyncStream { continuation in
            continuation.yield(.unavailable)
            continuation.finish()
        }
    }

    func signInForCloudMachines() {}

    func cloudMachinesPlanSummary() async -> CloudMachinesPlanSummary? {
        nil
    }

    var cloudMachinesAccountID: String? {
        nil
    }

    func cloudMachinesPlanIncludesCloud() async -> Bool? {
        nil
    }

    func openCloudMachinesPanel() {}

    func openCloudMachinesBilling() {}

    func openCloudVPNSetup() {}
}
