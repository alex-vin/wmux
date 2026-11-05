import AppKit
@testable import WmuxTerminal

@MainActor
struct FakeTerminalSurfaceViewProvider: TerminalSurfaceViewProviding {
    let surfaceView: FakeTerminalSurfaceNativeView
    let paneHost: FakeTerminalSurfacePaneHost

    func makeSurfaceViews(
        initialFrame: NSRect
    ) -> (surfaceView: any TerminalSurfaceNativeViewing, paneHost: any TerminalSurfacePaneHosting) {
        _ = initialFrame
        return (surfaceView, paneHost)
    }
}
