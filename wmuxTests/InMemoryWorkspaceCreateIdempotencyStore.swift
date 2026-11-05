import Foundation

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class InMemoryWorkspaceCreateIdempotencyStore:
    TerminalController.WorkspaceCreateIdempotencyPersisting {
    private var operationIDs: [UUID] = []

    func loadOperationIDs() -> [UUID] { operationIDs }

    func saveOperationIDs(_ operationIDs: [UUID]) {
        self.operationIDs = operationIDs
    }
}
