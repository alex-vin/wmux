import Foundation

extension WMUXCLI {
    struct SimulatorAgentRequest {
        let method: String
        let params: [String: Any]
        let timeout: TimeInterval?
        let output: SimulatorAgentOutput
    }
}
