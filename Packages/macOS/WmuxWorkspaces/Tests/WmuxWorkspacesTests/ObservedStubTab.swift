import Foundation
@testable import WmuxWorkspaces

@MainActor
final class ObservedStubTab: WorkspaceTabRepresenting {
    let id = UUID()
    var groupId: UUID?
    var isPinned = false
    var currentDirectory = "/tmp"
}
