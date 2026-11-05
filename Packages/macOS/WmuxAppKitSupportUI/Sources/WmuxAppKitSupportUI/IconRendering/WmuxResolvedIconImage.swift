public import SwiftUI

/// SwiftUI bridge for appearance-resolved AppKit icons.
@MainActor
public struct WmuxResolvedIconImage: NSViewRepresentable {
    public let request: WmuxResolvedIconRequest?

    /// Creates a SwiftUI icon backed by ``WmuxResolvedIconImageView``.
    public init(request: WmuxResolvedIconRequest?) {
        self.request = request
    }

    public func makeNSView(context: Context) -> WmuxResolvedIconImageView {
        WmuxResolvedIconImageView(frame: .zero)
    }

    public func updateNSView(_ nsView: WmuxResolvedIconImageView, context: Context) {
        nsView.apply(request)
    }
}
