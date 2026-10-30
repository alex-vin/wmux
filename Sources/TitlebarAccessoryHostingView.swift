import AppKit
import SwiftUI

final class TitlebarAccessoryHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        // Deliver hits directly to the hosting view and its SwiftUI controls.
        // TitlebarAccessoryContainerView handles drag in the surrounding titlebar areas.
        return super.hitTest(point) ?? self
    }
}

typealias NonDraggableHostingView<Content: View> = TitlebarAccessoryHostingView<Content>
