import Foundation

/// Stable metadata WMUX uses to identify and present an in-process sidebar provider.
public struct WmuxSidebarProviderDescriptor: Identifiable, Codable, Equatable, Sendable {
    /// Provider id for the built-in workspace sidebar.
    public static let defaultWorkspacesID = "wmux.sidebar.default"

    /// Stable provider identifier persisted in user selection state.
    public var id: String
    /// Localized provider title shown in sidebar provider menus.
    public var title: WmuxSidebarProviderLocalizedText
    /// Optional localized detail text shown under the provider title.
    public var subtitle: WmuxSidebarProviderLocalizedText?
    /// SF Symbols name used for this provider in menus.
    public var systemImageName: String
    /// Whether the provider is supplied by WMUX rather than a package example.
    public var isHostProvided: Bool

    /// Creates sidebar provider metadata.
    public init(
        id: String,
        title: WmuxSidebarProviderLocalizedText,
        subtitle: WmuxSidebarProviderLocalizedText? = nil,
        systemImageName: String,
        isHostProvided: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImageName = systemImageName
        self.isHostProvided = isHostProvided
    }

    /// Descriptor for WMUX's built-in workspace sidebar.
    public static let defaultWorkspaces = WmuxSidebarProviderDescriptor(
        id: defaultWorkspacesID,
        title: WmuxSidebarProviderLocalizedText(key: "sidebar.provider.default.title", defaultValue: "Default Workspaces"),
        subtitle: WmuxSidebarProviderLocalizedText(key: "sidebar.provider.default.subtitle", defaultValue: "wmux"),
        systemImageName: "list.bullet",
        isHostProvided: true
    )
}
