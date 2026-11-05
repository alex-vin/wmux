import Foundation

/// Current sidebar state delivered by WMUX to a sidebar extension.
public struct WmuxSidebarContext: Sendable {
    /// Latest workspace snapshot filtered to the permissions granted by the user.
    public let snapshot: WmuxSidebarSnapshot

    /// Read scopes WMUX granted for this snapshot.
    public let grantedReadScopes: Set<WmuxExtensionScope>

    /// Host actions WMUX will currently accept from this extension.
    public let grantedActionScopes: Set<WmuxExtensionActionScope>

    /// Typed command channel back to WMUX.
    public let host: WmuxSidebarHost

    @MainActor
    public init(
        snapshot: WmuxSidebarSnapshot,
        grantedReadScopes: Set<WmuxExtensionScope>? = nil,
        grantedActionScopes: Set<WmuxExtensionActionScope>? = nil,
        host: WmuxSidebarHost
    ) {
        self.snapshot = snapshot
        self.grantedReadScopes = grantedReadScopes ?? snapshot.grantedReadScopes
        self.grantedActionScopes = grantedActionScopes ?? snapshot.grantedActionScopes
        self.host = host
    }
}
