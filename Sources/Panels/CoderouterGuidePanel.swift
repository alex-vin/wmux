import AppKit
import Combine
import SwiftUI

/// A workspace pane that keeps the CodeRouter guide available beside the user's work.
@MainActor
final class CoderouterGuidePanel: Panel {
    let id: UUID
    let stableSurfaceIdentity = PanelStableSurfaceIdentity()
    let panelType: PanelType = .coderouterGuide

    var displayTitle: String {
        String(localized: "coderouter.guide.title", defaultValue: "coderouter")
    }

    var displayIcon: String? { "questionmark.circle" }

    init(id: UUID = UUID()) {
        self.id = id
    }

    func close() {}
    func focus() {}
    func unfocus() {}
    func triggerFlash(reason: WorkspaceAttentionFlashReason) {
        _ = reason
    }
}

struct CoderouterGuidePanelView: View {
    let isFocused: Bool
    let onRequestPanelFocus: () -> Void

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isFocused {
                    onRequestPanelFocus()
                }
            }
    }
}
