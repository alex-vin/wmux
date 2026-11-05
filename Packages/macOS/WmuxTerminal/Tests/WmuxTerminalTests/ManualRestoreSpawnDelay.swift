@testable import WmuxTerminal

@MainActor
final class ManualRestoreSpawnDelay: TerminalSurfaceRestoreSpawnDelayCancelling {
    func cancel() {}
}
