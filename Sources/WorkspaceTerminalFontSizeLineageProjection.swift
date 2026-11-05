import WmuxTerminal
import WmuxTerminalCore
import Foundation

extension WorkspaceTerminalFontSizeSnapshotProjection {
    struct LineageProjection {
        let lineage: TerminalFontSizeLineage?
        let representedRequestTokens: Set<UUID>
    }
}
