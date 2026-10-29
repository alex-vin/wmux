import Foundation

extension TerminalController {
    func v2MobileSimulatorDispatch(
        method: String,
        params: [String: Any],
        connectionID: UUID?
    ) -> V2CallResult {
        .err(code: "unsupported", message: "Mobile simulator is disabled in local build", data: nil)
    }

    func mobileSimulatorPanels(in workspace: Workspace) -> [SimulatorPanel] {
        []
    }
}
