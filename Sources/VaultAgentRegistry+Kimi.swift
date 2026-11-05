import WMUXAgentLaunch

extension WmuxVaultAgentRegistration {
    /// True only for cmux's exact built-in registration, not user registrations reusing its id.
    var isBuiltInKimi: Bool {
        self == Self.builtInKimi
    }

    static var builtInKimi: WmuxVaultAgentRegistration {
        WmuxVaultAgentRegistration(
            id: "kimi",
            name: RestorableAgentKind.kimi.displayName,
            detect: WmuxVaultAgentDetectRule(processNames: ["kimi", "kimi-cli", "kimi-code"]),
            sessionIdSource: .argvOption("--resume"),
            resumeCommand: RegisteredAgentResumeKind.kimi.commandTemplate,
            cwd: .preserve
        )
    }
}
