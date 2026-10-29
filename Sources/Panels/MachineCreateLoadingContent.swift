import SwiftUI

struct MachineCreateOperation: Sendable {
    var id: UUID = UUID()
    var refusalCode: String? = nil
    var hitMachineLimit: Bool = false
    var failureOutput: String? = nil
    var request: Request = Request()
    var statusLabel: String = ""
    var startedAt: Date = Date()
    struct Request: Sendable {
        var displayName: String = ""
        var reservedWorkspaceID: UUID? = nil
    }
}

struct MachineCreateRowActions: Sendable {
    static func bound(coordinator: MachineCreateCoordinator) -> MachineCreateRowActions {
        MachineCreateRowActions()
    }
    func retry(_ id: UUID) {}
    func dismiss(_ id: UUID) {}
}

struct MachineCreateLoadingContent: View {
    let operation: MachineCreateOperation
    let actions: MachineCreateRowActions
    let elapsedSeconds: Int

    var body: some View {
        EmptyView()
    }
}
