import Foundation

/// Tabs available when WMUX opens a workspace popover for a provider row.
public enum WmuxSidebarProviderWorkspacePopoverTab: String, Codable, CaseIterable, Equatable, Sendable {
    /// Notes tab.
    case notes
    /// Browser previews tab.
    case browser
    /// Pull request details tab.
    case pullRequest
}
