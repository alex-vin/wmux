import Foundation

/// Result returned after WMUX handles a provider mutation.
public struct WmuxSidebarProviderCommandResult: Codable, Equatable, Sendable {
    /// Whether WMUX accepted and completed the command.
    public var ok: Bool

    /// Creates a command result.
    public init(ok: Bool) {
        self.ok = ok
    }
}
