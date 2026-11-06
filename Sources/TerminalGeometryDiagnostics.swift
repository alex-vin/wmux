import AppKit
import WmuxFoundation
import WmuxTerminal

/// App boundary for geometry refresh and diagnostics.
@MainActor
struct TerminalGeometryDiagnostics {
    struct Interval: Sendable {
        func end() {}
    }

    func begin(
        _ phase: TerminalSurfaceWorkDiagnostics.Phase = .layout,
        workspaceID: UUID?,
        transition: TerminalWorkContext.Transition = .unknown
    ) -> Interval {
        Interval()
    }

    /// App boundary for geometry refresh and diagnostics.
    func context(
        workspaceID: UUID?,
        transition: TerminalWorkContext.Transition = .unknown
    ) -> TerminalWorkContext {
        .init(transition: transition)
    }

    /// Only an active native window or owned divider drag establishes resize.
    func resizeTransition(in window: NSWindow?) -> TerminalWorkContext.Transition {
        guard let window else { return .unknown }
        return window.inLiveResize || TerminalWindowPortalRegistry.isInteractiveGeometryResizeActive(in: window)
            ? .resize : .unknown
    }

    func refresh(
        _ view: GhosttySurfaceScrollView,
        reason: String,
        transition: TerminalWorkContext.Transition
    ) {
        view.layoutSubtreeIfNeeded()
        view.surfaceView.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        view.surfaceView.displayIfNeeded()
        view.surfaceView.terminalSurface?.forceRefresh(reason: reason)
    }
}
