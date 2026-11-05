import Foundation

/// In-process sidebar provider used by WMUX-owned sidebar presentations.
public protocol WmuxSidebarProvider: Sendable {
    /// Stable metadata describing the provider in selection UI.
    var descriptor: WmuxSidebarProviderDescriptor { get }

    /// Builds a render model from the latest sidebar snapshot.
    func render(snapshot: WmuxSidebarProviderSnapshot) -> WmuxSidebarProviderRenderModel
}
