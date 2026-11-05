import Foundation

@_spi(WmuxHostTransport)
/// Host-side callbacks used by the sidebar XPC bridge.
public struct WmuxSidebarHostClient: Sendable {
    /// Returns the latest host snapshot that should be sent to an extension.
    public var snapshot: @Sendable () async throws -> WmuxSidebarSnapshot

    /// Dispatches a sidebar action from an extension into WMUX.
    public var dispatch: @Sendable (WmuxSidebarAction) async throws -> WmuxSidebarActionResult

    /// Creates a host client from snapshot and action-dispatch closures.
    public init(
        snapshot: @escaping @Sendable () async throws -> WmuxSidebarSnapshot,
        dispatch: @escaping @Sendable (WmuxSidebarAction) async throws -> WmuxSidebarActionResult
    ) {
        self.snapshot = snapshot
        self.dispatch = dispatch
    }
}
