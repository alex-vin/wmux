internal import Foundation

/// Builds a terminal-attached tmux session launcher with shell integration.
///
/// A new session receives the supplied shell command for both its first pane
/// and future windows. Before attaching an existing session, its cmux workspace
/// environment is rebound to the current relay without changing user options
/// or already-running commands.
public struct RemoteTmuxSessionCommandBuilder: Sendable {
    private let sessionName: String
    private let shellCommand: String

    /// Creates a named tmux session launcher.
    ///
    /// - Parameters:
    ///   - sessionName: Validated exact tmux session name.
    ///   - shellCommand: Shell command used for panes in a newly created session.
    public init(sessionName: String, shellCommand: String) {
        self.sessionName = sessionName
        self.shellCommand = shellCommand
    }

    /// A shell-quoted command that creates or attaches to the named session.
    public var remoteShellCommand: String {
        let resolver = RemoteExecutableCommandBuilder(
            executableName: "tmux",
            notFoundSentinel: RemoteTmuxCommandBuilder.notFoundSentinel
        )
        var scriptLines = [
            "wmux_session_name=$1",
            "wmux_shell_command=$2",
            "wmux_session_target=\"=$wmux_session_name\"",
            "wmux_tmux=\"$(\(resolver.resolutionProbeShellCommand))\" || exit $?",
            "if \"$wmux_tmux\" has-session -t \"$wmux_session_target\" 2>/dev/null; then",
        ]
        scriptLines.append(contentsOf: Self.workspaceEnvironmentRebindingLines.map { "  " + $0 })
        scriptLines += [
            "  exec \"$wmux_tmux\" attach-session -t \"$wmux_session_target\"",
            "fi",
            "if \"$wmux_tmux\" new-session -d \(Self.newSessionEnvironmentArguments) -s \"$wmux_session_name\" \"$wmux_shell_command\"; then",
        ]
        scriptLines.append(contentsOf: Self.workspaceEnvironmentRebindingLines.map { "  " + $0 })
        scriptLines += [
            "  \"$wmux_tmux\" set-option -t \"$wmux_session_target:\" default-command \"$wmux_shell_command\" >/dev/null || exit $?",
            "fi",
            "exec \"$wmux_tmux\" attach-session -t \"$wmux_session_target\"",
        ]
        let script = scriptLines.joined(separator: "\n")
        return ([
            "/bin/sh",
            "-c",
            script,
            "wmux-remote-tmux-session",
            sessionName,
            shellCommand,
        ])
        .map(\.remoteCommandShellQuoted)
        .joined(separator: " ")
    }

    private static let workspaceEnvironmentKeys = [
        "WMUX_BUNDLED_CLI_PATH",
        "WMUX_PERSISTENT_PTY_EXEC_HELPER",
        "WMUX_SHELL_INTEGRATION",
        "WMUX_SHELL_INTEGRATION_DIR",
        "WMUX_SOCKET_PATH",
        "WMUX_SSH_ATTEMPT_ID",
        "WMUX_TAB_ID",
        "WMUX_TERMINAL_LIFECYCLE_ID",
        "WMUX_WORKSPACE_ID",
    ]

    private static let surfaceEnvironmentKeys = [
        "WMUX_PANEL_ID",
        "WMUX_SURFACE_ID",
    ]

    private static let transientEnvironmentKeys = [
        "WMUX_INITIAL_COMMAND_FILE",
    ]

    private static var workspaceEnvironmentRebindingLines: [String] {
        workspaceEnvironmentKeys.map { key in
            "if [ \"${\(key)+x}\" = x ]; then \"$wmux_tmux\" set-environment -t \"$wmux_session_target\" \(key) \"$\(key)\" >/dev/null || exit $?; else \"$wmux_tmux\" set-environment -t \"$wmux_session_target\" -u \(key) >/dev/null || exit $?; fi"
        } + transientEnvironmentClearingLines + surfaceEnvironmentClearingLines
    }

    private static var newSessionEnvironmentArguments: String {
        let workspaceArguments = workspaceEnvironmentKeys.map { key in
            "-e \"\(key)=${\(key)-}\""
        }
        let transientArguments = transientEnvironmentKeys.map { key in
            "-e \"\(key)=${\(key)-}\""
        }
        let surfaceArguments = surfaceEnvironmentKeys.map { key in
            "-e \"\(key)=\""
        }
        return (workspaceArguments + transientArguments + surfaceArguments).joined(separator: " ")
    }

    private static var transientEnvironmentClearingLines: [String] {
        transientEnvironmentKeys.map { key in
            "\"$wmux_tmux\" set-environment -t \"$wmux_session_target\" -u \(key) >/dev/null || exit $?"
        }
    }

    private static var surfaceEnvironmentClearingLines: [String] {
        surfaceEnvironmentKeys.map { key in
            "\"$wmux_tmux\" set-environment -t \"$wmux_session_target\" -u \(key) >/dev/null || exit $?"
        }
    }
}
