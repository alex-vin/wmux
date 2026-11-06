import Foundation

extension TerminalController {
    func v2MobileAttachTicketCreate(params: [String: Any]) async -> V2CallResult {
        .err(code: "unsupported", message: "Mobile attach ticket is disabled in local build", data: nil)
    }
}
