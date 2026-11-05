internal import Foundation

/// Stages a remote terminal bootstrap over an SSH management exec channel.
///
/// The potentially large bootstrap is streamed on standard input. Interactive
/// transports such as SSH or Mosh then execute only the small staged path.
public struct RemoteBootstrapStagingCommandBuilder: Sendable {
    private let installerSSHArguments: [String]
    private let destination: String
    private let remoteRelayPort: Int
    private let bootstrapScript: String

    /// Creates a bootstrap staging builder.
    ///
    /// - Parameters:
    ///   - installerSSHArguments: SSH executable and options, excluding destination.
    ///   - destination: SSH destination or host alias.
    ///   - remoteRelayPort: Valid relay namespace used for the staged path.
    ///   - bootstrapScript: Remote shell bootstrap containing optional cmux ID placeholders.
    public init?(
        installerSSHArguments: [String],
        destination: String,
        remoteRelayPort: Int,
        bootstrapScript: String
    ) {
        guard !installerSSHArguments.isEmpty,
              !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (1...65_535).contains(remoteRelayPort),
              !bootstrapScript.isEmpty else {
            return nil
        }
        self.installerSSHArguments = installerSSHArguments
        self.destination = destination
        self.remoteRelayPort = remoteRelayPort
        self.bootstrapScript = bootstrapScript
    }

    /// Local shell code that substitutes runtime IDs and streams the bootstrap over SSH.
    ///
    /// The SSH command is one `/bin/sh -c` remote-command string so an account's
    /// configured login shell cannot parse the POSIX installer itself.
    public var preparationShellScript: String {
        let encodedBootstrapScript = Data(bootstrapScript.utf8).base64EncodedString()
        let installCommand = "/bin/sh -c \(remoteInstallShellScript.remoteCommandShellQuoted)"
        let sshPrefix = installerSSHArguments
            .map(\.remoteCommandShellQuoted)
            .joined(separator: " ")
        return [
            "wmux_workspace_id=\"${WMUX_WORKSPACE_ID:-}\"",
            "wmux_surface_id=\"${WMUX_SURFACE_ID:-}\"",
            "wmux_terminal_lifecycle_id=\"${WMUX_TERMINAL_LIFECYCLE_ID:-}\"",
            "wmux_ssh_attempt_id=\"${WMUX_SSH_ATTEMPT_ID:-}\"",
            "wmux_remote_bootstrap_b64=\(encodedBootstrapScript.remoteCommandShellQuoted)",
            "wmux_remote_bootstrap=\"$(printf %s \"$wmux_remote_bootstrap_b64\" | base64 -d 2>/dev/null || printf %s \"$wmux_remote_bootstrap_b64\" | base64 -D 2>/dev/null)\"",
            "wmux_sed_escape() { printf '%s' \"$1\" | sed 's/[\\/&\\\\]/\\\\&/g'; }",
            "wmux_workspace_id_escaped=\"$(wmux_sed_escape \"$wmux_workspace_id\")\"",
            "wmux_surface_id_escaped=\"$(wmux_sed_escape \"$wmux_surface_id\")\"",
            "wmux_terminal_lifecycle_id_escaped=\"$(wmux_sed_escape \"$wmux_terminal_lifecycle_id\")\"",
            "wmux_ssh_attempt_id_escaped=\"$(wmux_sed_escape \"$wmux_ssh_attempt_id\")\"",
            "wmux_remote_bootstrap=\"$(printf '%s' \"$wmux_remote_bootstrap\" | sed \"s/__CMUX_WORKSPACE_ID__/$wmux_workspace_id_escaped/g; s/__CMUX_SURFACE_ID__/$wmux_surface_id_escaped/g; s/__CMUX_TERMINAL_LIFECYCLE_ID__/$wmux_terminal_lifecycle_id_escaped/g; s/__CMUX_SSH_ATTEMPT_ID__/$wmux_ssh_attempt_id_escaped/g\")\"",
            "wmux_remote_install_stderr_file=\"$(mktemp \"${TMPDIR:-/tmp}/cmux-remote-bootstrap-install.XXXXXX\" 2>/dev/null || true)\"",
            "if [ -n \"$wmux_remote_install_stderr_file\" ]; then",
            "  printf '%s' \"$wmux_remote_bootstrap\" | command \(sshPrefix) -T \(destination.remoteCommandShellQuoted) \(installCommand.remoteCommandShellQuoted) 2>\"$wmux_remote_install_stderr_file\"",
            "  wmux_remote_install_status=$?",
            "else",
            "  printf '%s' \"$wmux_remote_bootstrap\" | command \(sshPrefix) -T \(destination.remoteCommandShellQuoted) \(installCommand.remoteCommandShellQuoted)",
            "  wmux_remote_install_status=$?",
            "fi",
            "if [ \"$wmux_remote_install_status\" -ne 0 ] && [ -n \"$wmux_remote_install_stderr_file\" ] && [ -s \"$wmux_remote_install_stderr_file\" ]; then",
            "  cat \"$wmux_remote_install_stderr_file\" >&2",
            "fi",
            "rm -f -- \"${wmux_remote_install_stderr_file:-}\" 2>/dev/null || true",
            "unset wmux_remote_bootstrap wmux_remote_bootstrap_b64 wmux_workspace_id wmux_surface_id wmux_terminal_lifecycle_id wmux_ssh_attempt_id wmux_workspace_id_escaped wmux_surface_id_escaped wmux_terminal_lifecycle_id_escaped wmux_ssh_attempt_id_escaped wmux_remote_install_stderr_file",
            "(exit \"$wmux_remote_install_status\")",
        ].joined(separator: "\n")
    }

    /// Small remote shell command that replaces the process with the staged bootstrap.
    ///
    /// OpenSSH hands its remote command to the account's configured login
    /// shell first. Quote the POSIX launcher as the argument to an explicit
    /// `/bin/sh -c` so fish/csh/nushell never parse the staged bootstrap
    /// command themselves.
    public var remoteExecutionShellScript: String {
        "/bin/sh -c \(stagedBootstrapLauncherScript.remoteCommandShellQuoted)"
    }

    /// Remote command argv that executes the staged bootstrap.
    ///
    /// Mosh forwards this argv to `mosh-server`, which executes it with
    /// `execvp` and no shell parsing, so the launcher must be real argv
    /// elements: a single command string would be treated as a literal
    /// executable pathname and fail.
    public var remoteExecutionCommandArguments: [String] {
        ["/bin/sh", "-c", stagedBootstrapLauncherScript]
    }

    private var stagedBootstrapLauncherScript: String {
        "exec /bin/sh \"$HOME/.cmux/relay/\(remoteRelayPort).bootstrap.sh\""
    }

    private var remoteInstallShellScript: String {
        [
            "set -eu",
            "umask 077",
            "wmux_bootstrap_path=\"$HOME/.cmux/relay/\(remoteRelayPort).bootstrap.sh\"",
            "mkdir -p \"$HOME/.cmux/relay\"",
            "cat > \"$wmux_bootstrap_path\"",
            "chmod 700 \"$wmux_bootstrap_path\" >/dev/null 2>&1 || true",
        ].joined(separator: "\n")
    }
}
