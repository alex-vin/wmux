import Foundation

/// Metadata and permission request declared by a WMUX extension.
public struct WmuxExtensionManifest: Codable, Equatable, Identifiable, Sendable {
    /// Stable reverse-DNS style identifier for the extension.
    public var id: String

    /// Human-readable extension name shown by WMUX permission and management UI.
    public var displayName: String

    /// Minimum WMUX extension API version required by this extension.
    @_spi(WmuxHostTransport) public var minimumAPIVersion: WmuxExtensionAPIVersion

    /// Sidebar data scopes the extension asks WMUX to include in snapshots.
    public var readScopes: [WmuxExtensionScope]

    /// Host action scopes the extension asks WMUX to allow.
    public var actionScopes: [WmuxExtensionActionScope]

    /// Creates a sidebar extension manifest.
    public init(
        id: String,
        displayName: String,
        readScopes: [WmuxExtensionScope] = [],
        actionScopes: [WmuxExtensionActionScope] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.minimumAPIVersion = .sidebarV2
        self.readScopes = readScopes
        self.actionScopes = actionScopes
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case minimumAPIVersion
        case readScopes
        case actionScopes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        minimumAPIVersion = try container.decodeIfPresent(WmuxExtensionAPIVersion.self, forKey: .minimumAPIVersion) ?? .sidebarV2
        readScopes = try container.decode([WmuxExtensionScope].self, forKey: .readScopes)
        actionScopes = try container.decodeIfPresent(
            [WmuxExtensionActionScope].self,
            forKey: .actionScopes
        ) ?? []
    }
}
