import WMUXAgentLaunch
import Testing

@Suite("WmuxVaultAgentPersistedSessionStore")
struct WmuxVaultAgentPersistedSessionStoreTests {
    @Test("Parses every Hermes resume spelling", arguments: [
        ["--resume", "durable-session"],
        ["--resume=durable-session"],
        ["-r", "durable-session"],
        ["-r=durable-session"],
        ["-rdurable-session"],
    ])
    func parsesHermesResumeSpellings(arguments: [String]) {
        #expect(
            WmuxVaultAgentPersistedSessionStore.hermesStateDB
                .explicitSessionID(arguments: arguments) == "durable-session"
        )
    }
}
