import AppKit
import WmuxBrowser
import WebKit

@MainActor
final class AgentSessionWebView: WmuxUndoableWebView {
    var onPointerDown: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        PaneFirstClickFocusSettings.isEnabled()
    }

    override func isWebContentUndoRedoCommandEquivalent(_ event: NSEvent) -> Bool {
        event.cmuxIsUndoRedoCommandEquivalent
    }

    override func mouseDown(with event: NSEvent) {
        onPointerDown?()
        super.mouseDown(with: event)
    }
}
