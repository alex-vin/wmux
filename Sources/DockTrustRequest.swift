struct DockTrustRequest: Identifiable, Sendable {
    var id: String { descriptor.fingerprint }
    let descriptor: WmuxActionTrustDescriptor
    let configPath: String
}
