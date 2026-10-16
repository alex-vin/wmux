import AppKit
import CmuxAppKitSupportUI
import CmuxGeminiQuota
import SwiftUI

/// Minimalist sidebar footer icon button displaying a sparkles icon and a micro health status dot at the bottom-right.
///
/// Tapping the button reveals `GeminiQuotaPopoverView` via native arrowless popover.
struct SidebarGeminiQuotaButton: View {
    private let buttonSize: CGFloat = 22
    private let iconSize: CGFloat = 12
    private let helpTitle = "Gemini 额度与账号"

    @EnvironmentObject private var tabManager: TabManager
    @State private var isPopoverPresented = false

    private var appDelegate: AppDelegate? {
        AppDelegate.shared
    }

    private var store: GeminiAccountStore? {
        appDelegate?.geminiAccountStore
    }

    private var coordinator: GeminiTerminalAccountCoordinator? {
        appDelegate?.geminiTerminalCoordinator
    }

    private var currentSurfaceID: UUID? {
        guard let tabId = tabManager.selectedTabId else { return nil }
        return tabManager.focusedSurfaceId(for: tabId)
    }

    private var healthStatus: GeminiQuotaHealthStatus {
        guard let store else { return .disabled }
        if let currentSurfaceID, let bound = coordinator?.effectiveAccount(for: currentSurfaceID) {
            return store.healthStatus(for: bound)
        }
        if let defaultAcc = store.defaultAccount {
            return store.healthStatus(for: defaultAcc)
        }
        return .disabled
    }

    var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                CmuxSystemSymbolImage(
                    systemName: "sparkles",
                    pointSize: iconSize,
                    weight: .regular,
                    tint: Color(nsColor: .secondaryLabelColor)
                )
                .frame(width: buttonSize, height: buttonSize, alignment: .center)

                // Micro health indicator dot
                if let store, !store.accounts.isEmpty {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 4.5, height: 4.5)
                        .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 0.8))
                        .offset(x: -2.5, y: -2.5)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(SidebarFooterIconButtonStyle())
        .frame(width: buttonSize, height: buttonSize, alignment: .center)
        .background(
            ArrowlessPopoverAnchor(
                isPresented: $isPopoverPresented,
                preferredEdge: .maxY,
                detachedGap: 4
            ) {
                if let store, let coordinator {
                    GeminiQuotaPopoverView(
                        store: store,
                        coordinator: coordinator,
                        currentSurfaceID: currentSurfaceID
                    )
                }
            }
        )
        .accessibilityElement(children: .ignore)
        .safeHelp(helpTitle)
        .hintableAccessibilityLabel(helpTitle)
        .accessibilityIdentifier("SidebarGeminiQuotaButton")
    }

    private var dotColor: Color {
        switch healthStatus {
        case .healthy: .green
        case .warning: .orange
        case .critical: .red
        case .disabled: .secondary.opacity(0.6)
        }
    }
}
