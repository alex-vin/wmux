import CmuxCloudBannerCore
import CmuxCloud
import AppKit
import SwiftUI

/// Only active VPN operations and plan notices occupy space above the tree.
struct MachinesPanelBanners: View {
    let tunnelBanner: CloudTunnelBanner?
    let plan: MachinePlanSnapshot?
    let bannerDismissals: CloudBannerDismissalStore
    let chromeBackgroundColor: NSColor

    var body: some View {
        if let banner = tunnelBanner, banner.showsInMachinesPanel,
           !bannerDismissals.isDismissed(id: "machines.tunnel", signature: banner.dismissalSignature) {
            MachinesTunnelBanner(
                banner: banner,
                backgroundColor: chromeBackgroundColor,
                openSystemSettings: {
                    SystemExtensionSettingsLink.open()
                },
                onDismiss: {
                    bannerDismissals.dismiss(id: "machines.tunnel", signature: banner.dismissalSignature)
                }
            )
        }
    }
}
