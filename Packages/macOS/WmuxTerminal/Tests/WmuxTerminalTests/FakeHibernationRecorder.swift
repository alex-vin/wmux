import Foundation
@testable import WmuxTerminal

final class FakeHibernationRecorder: AgentHibernationRecording {
    @MainActor
    func recordTerminalInput(workspaceId: UUID, panelId: UUID) {}
}
