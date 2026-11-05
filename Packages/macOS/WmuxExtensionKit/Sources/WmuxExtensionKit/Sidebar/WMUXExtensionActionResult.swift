import Foundation

@_spi(WmuxHostTransport)
/// Result returned by WMUX for a sidebar host action request.
public struct WmuxSidebarActionResult: Codable, Equatable, Sendable {
    /// Whether WMUX accepted and applied the action.
    public var accepted: Bool

    /// Optional host-supplied result or rejection message.
    public var message: String?

    /// Structured reason when the action was rejected.
    public var rejectionReason: WmuxSidebarActionRejectionReason?

    /// Creates an action result.
    public init(
        accepted: Bool,
        message: String? = nil,
        rejectionReason: WmuxSidebarActionRejectionReason? = nil
    ) {
        self.accepted = accepted
        self.message = message
        self.rejectionReason = accepted ? nil : rejectionReason
    }

    /// Successful action result.
    public static let accepted = WmuxSidebarActionResult(accepted: true)

    /// Creates a rejected action result with a displayable message.
    public static func rejected(
        _ message: String,
        reason: WmuxSidebarActionRejectionReason = .rejected
    ) -> WmuxSidebarActionResult {
        WmuxSidebarActionResult(accepted: false, message: message, rejectionReason: reason)
    }

    /// Rejected action result used when the caller cancels an in-flight request.
    public static let cancelled = WmuxSidebarActionResult(
        accepted: false,
        message: "Extension action was cancelled",
        rejectionReason: .cancelled
    )
}

@_spi(WmuxHostTransport)
/// Machine-readable reason WMUX rejected a sidebar action.
public enum WmuxSidebarActionRejectionReason: String, Codable, Equatable, Sendable {
    /// Generic host rejection.
    case rejected

    /// The caller cancelled the action before the host completed it.
    case cancelled
}

/// Error thrown by typed `WmuxSidebarHost` action helpers.
public enum WmuxSidebarActionError: Error, Equatable, Sendable {
    /// WMUX rejected the action with a displayable message.
    case rejected(String)

    /// The caller cancelled the action before completion.
    case cancelled
}
