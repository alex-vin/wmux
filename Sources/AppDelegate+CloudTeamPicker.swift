import AppKit

extension AppDelegate {
    /// Inert in this build: the Cloud panel is not part of the sidebar, so
    /// there is no Invite popover to open. Kept so the socket path
    /// (``HostAccountFlow/showTeamInvite(preferredWindow:)``) still resolves.
    @MainActor
    @discardableResult
    func openCloudTeamInvite(preferredWindow: NSWindow? = nil, debugSource: String) -> Bool {
        _ = preferredWindow
        _ = debugSource
        return false
    }
}
