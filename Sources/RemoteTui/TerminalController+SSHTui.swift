import WmuxCore
import WmuxFoundation
import WmuxSurfaceCatalogModel
import Foundation

extension TerminalController {
    @MainActor
    func openSSHTuiWorkspace(params: [String: Any]) async throws -> [String: Any] {
        throw SurfaceCatalogError.unsupported("SSH TUI workspaces are disabled in local build")
    }
}
