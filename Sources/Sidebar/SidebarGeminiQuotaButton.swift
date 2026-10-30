import AppKit
import CmuxAppKitSupportUI
import CmuxGeminiQuota
import SwiftUI

/// Floating Gemini quota indicator button located at the bottom-left corner of the window.
///
/// Tapping the button displays `GeminiQuotaPopoverView` upward via a native arrowless popover.
struct FloatingGeminiQuotaButton: View {
    private let buttonSize: CGFloat = 30
    private let iconSize: CGFloat = 13
    private let helpTitle = "Gemini 额度与账号"

    @EnvironmentObject private var tabManager: TabManager
    @State private var isPopoverPresented = false
    @State private var isHovering = false

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
                    weight: .medium,
                    tint: Color(nsColor: isHovering ? .labelColor : .secondaryLabelColor)
                )
                .frame(width: buttonSize, height: buttonSize, alignment: .center)

                // Micro health indicator dot
                if let store, !store.accounts.isEmpty {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 5.5, height: 5.5)
                        .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1))
                        .offset(x: -3, y: -3)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(isHovering ? 0.95 : 0.78))
            )
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isHovering ? 0.22 : 0.12), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(isHovering ? 0.25 : 0.14), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .frame(width: buttonSize, height: buttonSize)
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .background(
            ArrowlessPopoverAnchor(
                isPresented: $isPopoverPresented,
                preferredEdge: .maxY,
                detachedGap: 8
            ) {
                if let store, let coordinator {
                    GeminiQuotaPopoverView(
                        store: store,
                        coordinator: coordinator,
                        currentSurfaceID: currentSurfaceID,
                        onClose: { isPopoverPresented = false }
                    )
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("正在加载 Gemini 服务...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 220, height: 100)
                }
            }
        )
        .background(FloatingGeminiQuotaButtonHitRegion())
        .accessibilityElement(children: .ignore)
        .safeHelp(helpTitle)
        .hintableAccessibilityLabel(helpTitle)
        .accessibilityIdentifier("FloatingGeminiQuotaButton")
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

/// Backward compatibility stub for legacy sidebar references.
struct SidebarGeminiQuotaButton: View {
    var body: some View {
        FloatingGeminiQuotaButton()
    }
}

/// Invisible hit region tracker for the floating Gemini quota button.
struct FloatingGeminiQuotaButtonHitRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> FloatingGeminiQuotaButtonHitRegionView {
        FloatingGeminiQuotaButtonHitRegionView(frame: .zero)
    }

    func updateNSView(_ nsView: FloatingGeminiQuotaButtonHitRegionView, context: Context) {}
}

final class FloatingGeminiQuotaButtonHitRegionView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        autoresizingMask = [.width, .height]
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            FloatingGeminiQuotaButtonHitRegionRegistry.register(self)
        } else {
            FloatingGeminiQuotaButtonHitRegionRegistry.unregister(self)
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview == nil {
            FloatingGeminiQuotaButtonHitRegionRegistry.unregister(self)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    deinit {
        FloatingGeminiQuotaButtonHitRegionRegistry.unregister(self)
    }
}

/// Thread-safe registry tracking the visible window bounds of floating Gemini quota buttons.
public enum FloatingGeminiQuotaButtonHitRegionRegistry: Sendable {
    private static let lock = NSLock()
    private static let registeredViews = NSHashTable<NSView>.weakObjects()

    public static func register(_ view: NSView) {
        lock.lock()
        registeredViews.add(view)
        lock.unlock()
    }

    public static func unregister(_ view: NSView) {
        lock.lock()
        registeredViews.remove(view)
        lock.unlock()
    }

    private static func snapshot() -> [NSView] {
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        return views
    }

    @MainActor
    private static func isVisibleInHierarchy(_ view: NSView) -> Bool {
        var current: NSView? = view
        while let candidate = current {
            guard !candidate.isHidden, candidate.alphaValue > 0 else { return false }
            current = candidate.superview
        }
        return true
    }

    @MainActor
    public static func containsWindowPoint(_ windowPoint: NSPoint, in window: NSWindow) -> Bool {
        let views = snapshot()
        if !views.isEmpty {
            for view in views {
                guard view.window === window, isVisibleInHierarchy(view) else { continue }
                let frameInWindow = view.convert(view.bounds, to: nil)
                let hitRect = frameInWindow.insetBy(dx: -4, dy: -4)
                if hitRect.contains(windowPoint) {
                    return true
                }
            }
            return false
        }
        // Cold-launch fallback only when view has not yet mounted in the hierarchy
        if isMainWorkspaceWindow(window) {
            let rect = NSRect(x: 10, y: 8, width: 38, height: 38)
            return rect.contains(windowPoint)
        }
        return false
    }
}
