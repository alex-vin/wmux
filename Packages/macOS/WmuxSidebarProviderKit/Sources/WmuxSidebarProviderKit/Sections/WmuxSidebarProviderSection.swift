import Foundation

/// Rendered section with tree metadata and concrete rows.
public struct WmuxSidebarProviderSection: Identifiable, Codable, Equatable, Sendable {
    /// Stable section id.
    public var id: String
    /// Tree/list section metadata.
    public var treeSection: WmuxSidebarProviderTreeSection
    /// Rows rendered in this section.
    public var rows: [WmuxSidebarProviderRow]

    /// Creates a provider section.
    public init(
        id: String,
        treeSection: WmuxSidebarProviderTreeSection,
        rows: [WmuxSidebarProviderRow]
    ) {
        self.id = id
        self.treeSection = treeSection
        self.rows = rows
    }
}
