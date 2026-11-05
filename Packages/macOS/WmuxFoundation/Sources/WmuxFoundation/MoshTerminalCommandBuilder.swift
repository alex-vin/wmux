internal import Foundation

/// Builds a Mosh terminal command with explicit SSH capability fallback.
///
/// The builder receives complete SSH argument prefixes from the caller so the
/// Mosh capability probe and bootstrap honor the same host alias, identity,
/// port, and OpenSSH options as the workspace control connection.
public struct MoshTerminalCommandBuilder: Sendable {
    private let capabilityProbeSSHArguments: [String]
    private let sessionSSHArguments: [String]
    private let localMoshExecutableName: String
    private let destination: String
    private let remoteCommandArguments: [String]
    private let remoteRelayPort: Int?
    private let remoteIPMode: MoshRemoteIPMode
    private let preparationShellScript: String?
    private let managementReadyShellScript: String?
    private let sshFallbackCommand: String
    private let sshFallbackLauncherPaths: [String]
    private let localMoshMissingMessage: String
    private let localMoshUnsupportedMessage: String
    private let remoteMoshMissingMessage: String
    private let remoteMoshProbeFailedMessage: String
    private let remoteBootstrapInstallFailedMessage: String
    private let remoteMoshAddressFallbackMessage: String

    /// Creates a Mosh terminal command builder.
    ///
    /// - Parameters:
    ///   - localMoshExecutableName: Local executable basename; injectable for deterministic tests.
    ///   - capabilityProbeSSHArguments: SSH executable and options used to check for `mosh-server`.
    ///   - sessionSSHArguments: SSH executable and options passed to Mosh's `--ssh` bootstrap.
    ///   - destination: SSH destination or host alias.
    ///   - remoteCommandArguments: Optional command argv launched by `mosh-server`.
    ///   - remoteRelayPort: Optional remote relay whose presence enables authoritative lifecycle attempt registration.
    ///   - remoteIPMode: Address-discovery mode passed to Mosh; remote mode falls back to SSH proxy resolution when SSH advertises an unusable address.
    ///   - preparationShellScript: Optional local preparation run before capability checks.
    ///   - managementReadyShellScript: Optional local callback run after SSH preparation succeeds and before Mosh starts.
    ///   - sshFallbackCommand: Complete local SSH terminal command used when Mosh is unavailable.
    ///   - sshFallbackLauncherPaths: Launcher files that only `sshFallbackCommand` runs. Each deletes
    ///     itself when it runs, so they are removed before Mosh replaces the shell.
    ///   - localMoshMissingMessage: User-facing message printed when no local `mosh` executable exists.
    ///   - localMoshUnsupportedMessage: User-facing message printed when local Mosh lacks the required remote-IP mode.
    ///   - remoteMoshMissingMessage: User-facing message printed when `mosh-server` is absent remotely.
    ///   - remoteMoshProbeFailedMessage: User-facing message printed when the remote capability probe fails.
    ///   - remoteBootstrapInstallFailedMessage: User-facing message printed when bootstrap staging fails.
    ///   - remoteMoshAddressFallbackMessage: User-facing message printed when SSH proxy address resolution is selected automatically.
    public init(
        capabilityProbeSSHArguments: [String],
        sessionSSHArguments: [String],
        localMoshExecutableName: String = "mosh",
        destination: String,
        remoteCommandArguments: [String],
        remoteRelayPort: Int? = nil,
        remoteIPMode: MoshRemoteIPMode = .remote,
        preparationShellScript: String? = nil,
        managementReadyShellScript: String? = nil,
        sshFallbackCommand: String,
        sshFallbackLauncherPaths: [String] = [],
        localMoshMissingMessage: String,
        localMoshUnsupportedMessage: String,
        remoteMoshMissingMessage: String,
        remoteMoshProbeFailedMessage: String,
        remoteBootstrapInstallFailedMessage: String,
        remoteMoshAddressFallbackMessage: String
    ) {
        self.capabilityProbeSSHArguments = capabilityProbeSSHArguments
        self.sessionSSHArguments = sessionSSHArguments
        self.localMoshExecutableName = localMoshExecutableName
        self.destination = destination
        self.remoteCommandArguments = remoteCommandArguments
        self.remoteRelayPort = remoteRelayPort
        self.remoteIPMode = remoteIPMode
        self.preparationShellScript = preparationShellScript
        self.managementReadyShellScript = managementReadyShellScript
        self.sshFallbackCommand = sshFallbackCommand
        self.sshFallbackLauncherPaths = sshFallbackLauncherPaths
        self.localMoshMissingMessage = localMoshMissingMessage
        self.localMoshUnsupportedMessage = localMoshUnsupportedMessage
        self.remoteMoshMissingMessage = remoteMoshMissingMessage
        self.remoteMoshProbeFailedMessage = remoteMoshProbeFailedMessage
        self.remoteBootstrapInstallFailedMessage = remoteBootstrapInstallFailedMessage
        self.remoteMoshAddressFallbackMessage = remoteMoshAddressFallbackMessage
    }

    /// Returns a shell command that launches Mosh or falls back to SSH.
    ///
    /// Capability detection happens before Mosh starts: the local executable is
    /// resolved from `PATH`, then the remote host is checked for `mosh-server`
    /// through the supplied SSH management lane. Exit status 127 represents an
    /// honest remote-missing result; other probe failures use the generic SSH
    /// fallback without pretending Mosh support was confirmed.
    ///
    /// - Returns: A complete `/bin/sh -c` terminal startup command.
    public func command() -> String {
        let localMoshResolver = RemoteExecutableCommandBuilder(
            executableName: localMoshExecutableName,
            notFoundSentinel: "wmux-mosh: local mosh not found"
        )
        let remoteMoshServerResolver = RemoteExecutableCommandBuilder(
            executableName: "mosh-server",
            notFoundSentinel: "wmux-mosh: remote mosh-server not found"
        )
        let remoteCapabilityCommand =
            remoteMoshServerResolver.resolutionProbeShellCommand + " >/dev/null 2>&1"
        let capabilityProbe = (capabilityProbeSSHArguments + [
            "-T",
            destination,
            remoteCapabilityCommand,
        ])
            .map(\.remoteCommandShellQuoted)
            .joined(separator: " ")
        let remoteSSHConnectionScript = "printf '%s\\n' \"__CMUX_SSH_CONNECTION__${SSH_CONNECTION:-}\""
        let remoteSSHConnectionCommand = "/bin/sh -c \(remoteSSHConnectionScript.remoteCommandShellQuoted)"
        let remoteSSHConnectionProbe = (capabilityProbeSSHArguments + [
            "-T",
            destination,
            remoteSSHConnectionCommand,
        ])
            .map(\.remoteCommandShellQuoted)
            .joined(separator: " ")
        let moshSSHCommand = sessionSSHArguments
            .map(\.remoteCommandShellQuoted)
            .joined(separator: " ")
        let moshArguments = ([
            "--ssh=\(moshSSHCommand)",
            "--server=\(remoteMoshServerResolver.remoteExecPrefixShellCommand)",
            "--",
            destination,
        ] + remoteCommandArguments)
            .map(\.remoteCommandShellQuoted)
            .joined(separator: " ")
        var script = [
            "wmux_mosh_fallback() { exec /bin/sh -c \(sshFallbackCommand.remoteCommandShellQuoted); }",
            "wmux_mosh=\"$(\(localMoshResolver.resolutionProbeShellCommand) 2>/dev/null)\"",
            "wmux_mosh_resolve_status=$?",
            "if [ \"$wmux_mosh_resolve_status\" -ne 0 ] || [ -z \"$wmux_mosh\" ]; then",
            "  printf '%s\\n' \(localMoshMissingMessage.remoteCommandShellQuoted) >&2",
            "  wmux_mosh_fallback",
            "fi",
            "unset wmux_mosh_resolve_status",
            "wmux_mosh_help=$(\"$wmux_mosh\" --help 2>&1 || true)",
            "case \"$wmux_mosh_help\" in",
            "  *--experimental-remote-ip=*) ;;",
            "  *)",
            "    printf '%s\\n' \(localMoshUnsupportedMessage.remoteCommandShellQuoted) >&2",
            "    wmux_mosh_fallback",
            "    ;;",
            "esac",
            "unset wmux_mosh_help",
        ]
        let reportsTerminalLifecycle = remoteRelayPort.map { (1...65_535).contains($0) } ?? false
        if reportsTerminalLifecycle {
            script += terminalLifecycleAttemptShellLines()
        }
        if let preparationShellScript = preparationShellScript?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !preparationShellScript.isEmpty {
            script += [
                preparationShellScript,
                "wmux_mosh_prepare_status=$?",
                "if [ \"$wmux_mosh_prepare_status\" -ne 0 ]; then",
                "  printf '%s\\n' \(remoteBootstrapInstallFailedMessage.remoteCommandShellQuoted) >&2",
                "  wmux_mosh_fallback",
                "fi",
                "unset wmux_mosh_prepare_status wmux_remote_install_status",
            ]
        }
        script += [
            "wmux_mosh_remote_ip_mode=\(remoteIPMode.rawValue.remoteCommandShellQuoted)",
            "wmux_mosh_address_fallback=0",
        ]
        script += [
            capabilityProbe,
            "wmux_mosh_probe_status=$?",
            "if [ \"$wmux_mosh_probe_status\" -eq 127 ]; then",
            "  printf '%s\\n' \(remoteMoshMissingMessage.remoteCommandShellQuoted) >&2",
            "  wmux_mosh_fallback",
            "fi",
            "if [ \"$wmux_mosh_probe_status\" -ne 0 ]; then",
            "  printf '%s\\n' \(remoteMoshProbeFailedMessage.remoteCommandShellQuoted) >&2",
            "  wmux_mosh_fallback",
            "fi",
        ]
        if remoteIPMode == .remote {
            // Mosh parses SSH_CONNECTION as four space-separated fields with
            // numeric ports and uses only the server address for its UDP
            // session, so validate exactly that shape and no more. When the
            // advertised address is unusable (empty, malformed, wildcard, or
            // loopback, which is what a port-forwarded SSH alias reports),
            // fall back to Mosh's proxy resolution: unlike local mode it
            // honors SSH aliases without requiring DNS on the destination.
            script += [
                "wmux_mosh_ssh_connection_probe_status=0",
                "wmux_mosh_ssh_connection_probe=\"$(\(remoteSSHConnectionProbe) 2>/dev/null)\" || wmux_mosh_ssh_connection_probe_status=$?",
                "case \"$wmux_mosh_ssh_connection_probe\" in *__CMUX_SSH_CONNECTION__*) wmux_mosh_ssh_connection=\"${wmux_mosh_ssh_connection_probe##*__CMUX_SSH_CONNECTION__}\" ;; *) wmux_mosh_ssh_connection= ;; esac",
                "if [ \"$wmux_mosh_ssh_connection_probe_status\" -ne 0 ] || [ -z \"$wmux_mosh_ssh_connection\" ]; then",
                "  wmux_mosh_address_fallback=1",
                "else",
                "  case \"$wmux_mosh_ssh_connection\" in",
                "    *' '*' '*' '*)",
                "      wmux_mosh_ssh_connection_tail=\"${wmux_mosh_ssh_connection#* }\"",
                "      wmux_mosh_ssh_peer_port=\"${wmux_mosh_ssh_connection_tail%% *}\"",
                "      wmux_mosh_ssh_connection_tail=\"${wmux_mosh_ssh_connection_tail#* }\"",
                "      wmux_mosh_ssh_server_ip=\"${wmux_mosh_ssh_connection_tail%% *}\"",
                "      wmux_mosh_ssh_connection_tail=\"${wmux_mosh_ssh_connection_tail#* }\"",
                "      wmux_mosh_ssh_server_port=\"${wmux_mosh_ssh_connection_tail%% *}\"",
                "      case \"$wmux_mosh_ssh_peer_port\" in ''|*[!0-9]*) wmux_mosh_address_fallback=1 ;; esac",
                "      case \"$wmux_mosh_ssh_server_port\" in ''|*[!0-9]*) wmux_mosh_address_fallback=1 ;; esac",
                "      case \"$wmux_mosh_ssh_server_ip\" in ''|0.0.0.0|::|::0|::1|127.*) wmux_mosh_address_fallback=1 ;; *[!0-9A-Fa-f:.]*) wmux_mosh_address_fallback=1 ;; esac",
                "      ;;",
                "    *) wmux_mosh_address_fallback=1 ;;",
                "  esac",
                "fi",
                "if [ \"$wmux_mosh_address_fallback\" -eq 1 ]; then wmux_mosh_remote_ip_mode=proxy; fi",
                "unset wmux_mosh_ssh_connection_probe_status wmux_mosh_ssh_connection_probe wmux_mosh_ssh_connection wmux_mosh_ssh_peer_port wmux_mosh_ssh_connection_tail wmux_mosh_ssh_server_ip wmux_mosh_ssh_server_port",
            ]
        }
        script += [
            "if [ \"$wmux_mosh_address_fallback\" -eq 1 ]; then",
            "  printf '%s\\n' \(remoteMoshAddressFallbackMessage.remoteCommandShellQuoted) >&2",
            "fi",
            "unset wmux_mosh_probe_status wmux_mosh_address_fallback",
        ]
        if let managementReadyShellScript = managementReadyShellScript?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !managementReadyShellScript.isEmpty {
            script.append(managementReadyShellScript)
        }
        if reportsTerminalLifecycle {
            script += terminalLifecycleRegistrationShellLines()
        }
        // Past this point the SSH fallback can no longer run, so its
        // self-deleting launchers never would; remove them before Mosh
        // replaces this shell.
        if !sshFallbackLauncherPaths.isEmpty {
            script.append(
                "rm -f -- " + sshFallbackLauncherPaths.map(\.remoteCommandShellQuoted).joined(separator: " ")
            )
        }
        // Mosh exposes no reliable post-UDP-handshake callback, so this
        // pre-exec launcher must not claim authoritative connected readiness.
        script.append("exec \"$wmux_mosh\" \"--experimental-remote-ip=$wmux_mosh_remote_ip_mode\" \(moshArguments)")
        return "/bin/sh -c \(script.joined(separator: "\n").remoteCommandShellQuoted)"
    }

    private func terminalLifecycleAttemptShellLines() -> [String] {
        [
            "WMUX_SSH_ATTEMPT_ID=$(/usr/bin/uuidgen | /usr/bin/tr '[:upper:]' '[:lower:]') || wmux_mosh_fallback",
            "export WMUX_SSH_ATTEMPT_ID",
        ]
    }

    private func terminalLifecycleRegistrationShellLines() -> [String] {
        [
            "wmux_mosh_lifecycle_cli=\"${WMUX_BUNDLED_CLI_PATH:-}\"",
            "if [ -z \"$wmux_mosh_lifecycle_cli\" ] || [ ! -x \"$wmux_mosh_lifecycle_cli\" ]; then wmux_mosh_lifecycle_cli=\"$(command -v cmux 2>/dev/null || true)\"; fi",
            "if [ -z \"$wmux_mosh_lifecycle_cli\" ] || [ -z \"${WMUX_SOCKET_PATH:-}\" ] || [ -z \"${WMUX_WORKSPACE_ID:-}\" ] || [ -z \"${WMUX_SURFACE_ID:-}\" ] || [ -z \"${WMUX_TERMINAL_LIFECYCLE_ID:-}\" ]; then wmux_mosh_fallback; fi",
            "wmux_mosh_lifecycle_rpc() { wmux_mosh_lifecycle_method=\"$1\"; wmux_mosh_lifecycle_payload=\"$2\"; wmux_mosh_lifecycle_retry=0; while ! WMUXTERM_CLI_RESPONSE_TIMEOUT_SEC=2 \"$wmux_mosh_lifecycle_cli\" --socket \"$WMUX_SOCKET_PATH\" rpc \"$wmux_mosh_lifecycle_method\" \"$wmux_mosh_lifecycle_payload\" >/dev/null 2>&1; do wmux_mosh_lifecycle_retry=$((wmux_mosh_lifecycle_retry + 1)); if [ \"$wmux_mosh_lifecycle_retry\" -ge 4 ]; then return 1; fi; /bin/sleep 0.1; done; }",
            "wmux_mosh_launch_payload=\"{\\\"workspace_id\\\":\\\"$WMUX_WORKSPACE_ID\\\",\\\"surface_id\\\":\\\"$WMUX_SURFACE_ID\\\",\\\"terminal_lifecycle_id\\\":\\\"$WMUX_TERMINAL_LIFECYCLE_ID\\\",\\\"attempt_id\\\":\\\"$WMUX_SSH_ATTEMPT_ID\\\"}\"",
            "wmux_mosh_lifecycle_rpc workspace.remote.terminal_session_launching \"$wmux_mosh_launch_payload\" || wmux_mosh_fallback",
            "unset wmux_mosh_launch_payload wmux_mosh_lifecycle_cli wmux_mosh_lifecycle_method wmux_mosh_lifecycle_payload wmux_mosh_lifecycle_retry",
            "unset -f wmux_mosh_lifecycle_rpc 2>/dev/null || true",
        ]
    }
}
