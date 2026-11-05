import CmuxCloud
import Foundation

@MainActor
extension CmuxTuiSurfaceProvider {
    func reconcileManualMirrorAttachments(
        connected: CloudMachineLink.Connected,
        link: CloudMachineLink,
        lifecycle: UInt64,
        refresh generation: UInt64
    ) async -> Bool {
        true
    }

    func scheduleAttachmentRetry() {}
}
