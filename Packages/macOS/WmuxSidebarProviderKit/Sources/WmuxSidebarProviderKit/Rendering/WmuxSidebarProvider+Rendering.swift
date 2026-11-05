import Foundation

public extension WmuxSidebarProvider {
    /// Builds the default empty render model for providers that do not implement rendering.
    func render(snapshot: WmuxSidebarProviderSnapshot) -> WmuxSidebarProviderRenderModel {
        WmuxSidebarProviderRenderModel(
            providerId: descriptor.id,
            snapshotSequence: snapshot.sequence,
            sections: []
        )
    }

    /// Builds a render model using contextual rendering when available.
    func render(
        snapshot: WmuxSidebarProviderSnapshot,
        context: WmuxSidebarProviderRenderContext
    ) -> WmuxSidebarProviderRenderModel {
        render(snapshot: snapshot)
    }
}
