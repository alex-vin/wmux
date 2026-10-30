import SwiftUI
import AppKit

/// A sleek top status bar displayed above the terminal area whenever subagent tasks are active.
public struct SubagentStatusBarView: View {
    @State private var store = SubagentTaskStore.shared
    @State private var isPulsing: Bool = false

    public init() {}

    public var body: some View {
        if !store.activeTasks.isEmpty {
            HStack(spacing: 8) {
                // Leading Subagent icon / label
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("Subagents")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 4)

                Divider()
                    .frame(height: 12)

                // Horizontal scrollable list of active task capsules
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.activeTasks) { task in
                            SubagentTaskBadge(
                                task: task,
                                currentTimestamp: store.currentTimestamp,
                                isPulsing: isPulsing
                            ) {
                                store.focusSurface(surfaceID: task.surfaceID)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

/// Capsule badge displaying individual subagent task information.
struct SubagentTaskBadge: View {
    let task: SubagentTaskItem
    let currentTimestamp: Date
    let isPulsing: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Status indicator icon
                switch task.status {
                case .running:
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .scaleEffect(isPulsing ? 1.25 : 0.8)
                        .opacity(isPulsing ? 1.0 : 0.5)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.green)
                case .error:
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.red)
                }

                // Title
                Text(task.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                // Account label
                Text("(\(formatAccount(task.accountID)))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Elapsed time
                Text(formatElapsed(from: task.startTime, to: currentTimestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isHovered ? Color.green.opacity(0.5) : Color.primary.opacity(0.12),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(
            task.surfaceID.isEmpty
                ? "Subagent task: \(task.title)"
                : "Click to focus pane (\(task.surfaceID))"
        )
    }

    private func formatAccount(_ account: String) -> String {
        let trimmed = account.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "pool" {
            return "pool"
        }
        if let atIndex = trimmed.firstIndex(of: "@") {
            let name = trimmed[..<atIndex]
            return "\(name)@..."
        }
        return trimmed
    }

    private func formatElapsed(from start: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remSeconds = seconds % 60
        if minutes < 60 {
            return "\(minutes)m \(remSeconds)s"
        }
        let hours = minutes / 60
        let remMinutes = minutes % 60
        return "\(hours)h \(remMinutes)m"
    }
}
