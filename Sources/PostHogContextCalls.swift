import Foundation

/// PostHog context calls stubbed for local-only execution.
struct PostHogContextCalls: Sendable {
    var register: @Sendable ([String: Any]) -> Void

    static let live = PostHogContextCalls(
        register: { _ in }
    )
}
