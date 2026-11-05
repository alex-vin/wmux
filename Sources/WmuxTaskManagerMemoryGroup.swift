import Foundation

/// Decodes one command-name aggregate from the memory diagnostic payload.
struct WmuxTaskManagerMemoryGroup: Sendable {
    let id: String
    let name: String
    let rssBytes: Int64
    let processCount: Int
    let processIds: [Int]
    let attribution: WmuxTaskManagerMemoryGroupAttribution

    init?(_ payload: [String: Any]) {
        guard let name = WmuxTaskManagerMemoryDiagnostic.string(payload["name"]) else {
            return nil
        }
        let processCount = WmuxTaskManagerMemoryDiagnostic.int(payload["process_count"]) ?? 0
        guard processCount > 0 else { return nil }
        self.id = WmuxTaskManagerMemoryDiagnostic.string(payload["id"]) ?? name.lowercased()
        self.name = name
        self.rssBytes = WmuxTaskManagerMemoryDiagnostic.int64(payload["rss_bytes"])
        self.processCount = processCount
        self.processIds = WmuxTaskManagerMemoryDiagnostic.intArray(payload["pids"])
        let topAttribution = WmuxTaskManagerMemoryAttribution(payload["top_attribution"] as? [String: Any])
        self.attribution = WmuxTaskManagerMemoryGroupAttribution(
            payload["group_attribution"] as? [String: Any] ?? [:]
        )
            ?? topAttribution.map(WmuxTaskManagerMemoryGroupAttribution.common)
            ?? .unattributed
    }
}
