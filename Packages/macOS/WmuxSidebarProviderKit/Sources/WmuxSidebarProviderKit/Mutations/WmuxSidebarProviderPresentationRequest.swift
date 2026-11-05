import Foundation

/// Presentation command a provider can request from the WMUX sidebar host.
public enum WmuxSidebarProviderPresentationRequest: Codable, Equatable, Sendable {
    /// Open the workspace popover on a preferred tab.
    case openWorkspacePopover(workspaceId: UUID, preferredTab: WmuxSidebarProviderWorkspacePopoverTab)
    /// Open a detached workspace window on a preferred tab.
    case openWorkspaceWindow(workspaceId: UUID, preferredTab: WmuxSidebarProviderWorkspacePopoverTab)
    /// Ask WMUX to open a URL.
    case openURL(String)
}
