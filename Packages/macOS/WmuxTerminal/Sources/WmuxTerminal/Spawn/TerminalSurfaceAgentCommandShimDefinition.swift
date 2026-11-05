/// Agent commands that cmux can intercept with a per-surface launch shim.
public enum TerminalSurfaceAgentCommand: String, CaseIterable, Hashable, Sendable {
    case claude
    case codex
    case pi
    case amp
    case hermes
}

/// Describes one agent command intercepted by the shared per-surface shim path.
struct TerminalSurfaceAgentCommandShimDefinition: Sendable {
    let command: TerminalSurfaceAgentCommand
    let wrapperName: String
    let environmentVariablePrefix: String

    var commandName: String { command.rawValue }

    /// The single capability table for cmux-managed agent launch wrappers.
    static let bundled: [Self] = [
        Self(
            command: .claude,
            wrapperName: "wmux-claude-wrapper",
            environmentVariablePrefix: "WMUX_CLAUDE"
        ),
        Self(
            command: .codex,
            wrapperName: "wmux-codex-wrapper",
            environmentVariablePrefix: "WMUX_CODEX"
        ),
        Self(
            command: .pi,
            wrapperName: "wmux-pi-wrapper",
            environmentVariablePrefix: "WMUX_PI"
        ),
        Self(
            command: .amp,
            wrapperName: "wmux-amp-wrapper",
            environmentVariablePrefix: "WMUX_AMP"
        ),
        Self(
            command: .hermes,
            wrapperName: "wmux-hermes-agent-wrapper",
            environmentVariablePrefix: "WMUX_HERMES_AGENT"
        ),
    ]
}
