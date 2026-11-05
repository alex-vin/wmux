import Foundation

/// Provider that renders with explicit render context.
public protocol WmuxContextualSidebarProvider: WmuxSidebarProvider {
    /// Builds a render model from a sidebar snapshot and render context.
    func render(snapshot: WmuxSidebarProviderSnapshot, context: WmuxSidebarProviderRenderContext) -> WmuxSidebarProviderRenderModel
}
