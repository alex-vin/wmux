import WMUXAgentLaunch
import Foundation

extension WmuxVaultAgentRegistration {
    /// Amp's built-in Vault registration backed by cmux's managed hook store.
    static var builtInAmp: WmuxVaultAgentRegistration {
        WmuxVaultAgentRegistration(
            id: "amp",
            name: "Amp",
            iconAssetName: "AgentIcons/Amp",
            detect: WmuxVaultAgentDetectRule(processName: "amp"),
            sessionIdSource: .cmuxHookStore(.amp),
            resumeCommand: RegisteredAgentResumeKind.amp.commandTemplate,
            cwd: .preserve
        )
    }
}
