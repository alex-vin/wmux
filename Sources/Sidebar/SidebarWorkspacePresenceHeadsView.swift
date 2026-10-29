import AppKit
import CmuxWorkspacePresence
import SwiftUI

/// Renders the compact collaborator heads attached to a Cloud workspace row.
struct SidebarWorkspacePresenceHeadsView: View {
    let participants: [WorkspacePresenceParticipant]

    var body: some View {
        let layout = WorkspacePresencePolicy.layout(participants: participants)
        HStack(spacing: 2) {
            HStack(spacing: -5) {
                ForEach(layout.visible) { participant in
                    StackAccountAvatarView(
                        avatarURL: participant.avatarURL,
                        displayName: participant.displayName ?? "",
                        email: "",
                        size: 18
                    )
                    .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.25))
                    .opacity(WorkspacePresencePolicy.avatarOpacity(for: participant))
                }
            }
            if layout.overflow > 0 {
                Text(verbatim: "+\(layout.overflow)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 20)
        .fixedSize(horizontal: true, vertical: false)
        .help(WorkspacePresencePolicy.names(participants))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WorkspacePresencePolicy.accessibilityLabel(participants))
    }
}

struct StackAccountAvatarView: View {
    var avatarURL: URL? = nil
    var displayName: String = ""
    var email: String = ""
    var size: CGFloat = 18

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: size, height: size)
    }
}

struct WorkspacePresencePolicy {
    static let inactiveOpacity = 0.42

    static func layout(participants: [WorkspacePresenceParticipant], maximumVisible: Int = 4) -> (visible: [WorkspacePresenceParticipant], overflow: Int) {
        let limit = max(1, maximumVisible)
        var active: [WorkspacePresenceParticipant] = []
        var inactive: [WorkspacePresenceParticipant] = []
        for participant in participants {
            if participant.isActive {
                if active.count < limit { active.append(participant) }
            } else if inactive.count < limit {
                inactive.append(participant)
            }
        }
        var visible = Array(active.prefix(limit))
        if visible.count < limit {
            visible.append(contentsOf: inactive.prefix(limit - visible.count))
        }
        return (visible, max(0, participants.count - limit))
    }

    static func avatarOpacity(for participant: WorkspacePresenceParticipant) -> Double {
        participant.isActive ? 1 : inactiveOpacity
    }

    static func names(_ participants: [WorkspacePresenceParticipant]) -> String {
        participants.map { $0.displayName ?? "Collaborator" }.joined(separator: ", ")
    }

    static func accessibilityLabel(_ participants: [WorkspacePresenceParticipant]) -> String {
        names(participants)
    }
}
