public import Foundation

/// Injects phase recording without making the terminal package reach into app state.
public struct TerminalSurfaceWorkDiagnostics: Sendable {
    public struct Interval: Sendable {
        public func end() {}
    }
    public enum Phase: String, Sendable, Codable, CaseIterable {
        case layout
        case geometryPublication
        case geometryQueue
        case resizePublication
        case rendererRefresh
        case ptyResizeRequest
        case renderGridReplay
    }

    public init() {}

    @MainActor
    public func begin(_ phase: Phase, workspaceID: UUID) -> Interval? {
        return nil
    }
}
