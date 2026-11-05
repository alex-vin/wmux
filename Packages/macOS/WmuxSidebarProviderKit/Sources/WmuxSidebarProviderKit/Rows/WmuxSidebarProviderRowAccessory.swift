import Foundation

/// Accessory control displayed at the trailing edge of a provider row.
public struct WmuxSidebarProviderRowAccessory: Codable, Equatable, Sendable {
    /// Accessory behavior.
    public var kind: WmuxSidebarProviderRowAccessoryKind
    /// SF Symbols name for the accessory icon.
    public var systemImageName: String
    /// Default popover tab when the accessory opens workspace details.
    public var defaultTab: WmuxSidebarProviderWorkspacePopoverTab

    /// Creates a row accessory.
    public init(
        kind: WmuxSidebarProviderRowAccessoryKind,
        systemImageName: String,
        defaultTab: WmuxSidebarProviderWorkspacePopoverTab
    ) {
        self.kind = kind
        self.systemImageName = systemImageName
        self.defaultTab = defaultTab
    }

    /// Standard workspace inspector accessory.
    public static let inspector = WmuxSidebarProviderRowAccessory(
        kind: .workspaceInspector,
        systemImageName: "ellipsis.circle",
        defaultTab: .notes
    )
}
