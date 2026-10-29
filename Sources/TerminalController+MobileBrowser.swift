import Foundation

extension TerminalController {
    func v2MobileBrowserDispatch(
        method: String,
        params: [String: Any],
        connectionID: UUID?
    ) -> V2CallResult {
        .err(code: "unsupported", message: "Mobile browser is disabled in local build", data: nil)
    }

    func mobileBrowserRecordDiagnostic(_ event: Any? = nil) {}
    static func mobileBrowserPanelCorrelation(_ id: UUID) -> Int { 0 }
}
