import CmuxCloud
import CmuxSurfaceCatalogModel
import Foundation

extension CmuxTuiSurfaceProvider {
    func installNotificationSync() {}
    func syncNotifications(from state: CloudVMState) {}
    func syncAgentHooks(from state: CloudVMState) {}
    func notificationDeliveryTarget(for row: CloudVMNotificationRow) -> CloudNotificationDeliveryTarget? { nil }
    func deliverNotification(_ row: CloudVMNotificationRow, to target: CloudNotificationDeliveryTarget) -> CloudNotificationDeliveryOutcome { .declined }
}
