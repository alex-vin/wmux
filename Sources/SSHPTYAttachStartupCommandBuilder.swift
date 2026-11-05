import Foundation
import WmuxCore
import WmuxFoundation

enum SSHPTYAttachStartupCommandBuilder {
    struct ForegroundAuth {
        let destination: String
        let port: Int?
        let identityFile: String?
        let sshOptions: [String]
        /// The route state a ``WorkspaceRemoteConfiguration`` keeps beside
        /// its options, so the merge still picks the route's private master.
        let routeSensitivity: WorkspaceRemoteRouteSensitivity
        let token: String
        let postAuthenticationCommand: String?

        init(
            destination: String,
            port: Int?,
            identityFile: String?,
            sshOptions: [String],
            routeSensitivity: WorkspaceRemoteRouteSensitivity = .shared,
            token: String,
            postAuthenticationCommand: String? = nil
        ) {
            self.destination = destination
            self.port = port
            self.identityFile = identityFile
            self.sshOptions = sshOptions
            self.routeSensitivity = routeSensitivity
            self.token = token
            self.postAuthenticationCommand = postAuthenticationCommand
        }
    }

    static func command(
        sessionID: String? = nil,
        foregroundAuth: ForegroundAuth? = nil,
        remoteCommand: String? = nil,
        requireExisting: Bool = true
    ) -> String {
        let backoffBuilder = SSHRetryBackoffScriptBuilder(context: .attach)
        var lines = [
            "wmux_ssh_attach_cli=\"${WMUX_BUNDLED_CLI_PATH:-}\"",
            "if [ -z \"$wmux_ssh_attach_cli\" ] || [ ! -x \"$wmux_ssh_attach_cli\" ]; then wmux_ssh_attach_cli=\"$(command -v cmux 2>/dev/null || true)\"; fi",
            "if [ -z \"$wmux_ssh_attach_cli\" ]; then printf '%s\\n' '[cmux] bundled CLI not found for SSH PTY attach.' >&2; exit 127; fi",
            "if [ -z \"${WMUX_SOCKET_PATH:-}\" ]; then printf '%s\\n' '[cmux] required configuration missing for SSH PTY attach.' >&2; exit 1; fi",
            "if [ -z \"${WMUX_WORKSPACE_ID:-}\" ]; then printf '%s\\n' '[cmux] required workspace context missing for SSH PTY attach.' >&2; exit 1; fi",
        ]
        if let sessionID = normalized(sessionID) {
            lines.append("wmux_ssh_attach_session_id=\(shellQuote(sessionID))")
        } else {
            lines += [
                "wmux_ssh_attach_session_id=\"${WMUX_SSH_PTY_SESSION_ID:-}\"",
                "if [ -z \"$wmux_ssh_attach_session_id\" ]; then if [ -z \"${WMUX_SURFACE_ID:-}\" ]; then printf '%s\\n' '[cmux] required terminal context missing for SSH PTY attach.' >&2; exit 1; fi; wmux_ssh_attach_session_id=\"ssh-$WMUX_WORKSPACE_ID-$WMUX_SURFACE_ID\"; fi",
            ]
        }
        if let foregroundAuth {
            // The app passes the token in the environment. Keep it in a shell
            // variable for every retry, and out of the environment of the
            // commands this script starts.
            lines += SSHForegroundAuthenticationLaunch(token: foregroundAuth.token)
                .tokenLoadShellLines(into: "wmux_ssh_attach_auth_token")
            lines += foregroundAuthLines(foregroundAuth)
            lines.append(
                SSHForegroundAuthenticationRetryPolicy().processTreeTerminationShellFunction()
            )
        }
        lines.append("wmux_ssh_attach_lifecycle_id=\"${WMUX_SSH_PTY_LIFECYCLE_ID:-}\"")
        lines.append("if [ -z \"$wmux_ssh_attach_lifecycle_id\" ]; then wmux_ssh_attach_lifecycle_id=$(/usr/bin/uuidgen | /usr/bin/tr '[:upper:]' '[:lower:]') || exit 1; fi")
        lines += [
            "wmux_ssh_attach_lifecycle_ended=0",
            "wmux_ssh_attach_auth_pid=",
            "wmux_ssh_attach_auth_event_token=",
            "wmux_ssh_attach_lifecycle_end() { if [ \"$wmux_ssh_attach_lifecycle_ended\" = 1 ]; then return; fi; wmux_ssh_attach_lifecycle_ended=1; \"$wmux_ssh_attach_cli\" --socket \"$WMUX_SOCKET_PATH\" ssh-session-end --lifecycle-only --workspace \"$WMUX_WORKSPACE_ID\" --surface \"${WMUX_SURFACE_ID:-}\" --terminal-lifecycle-id \"${WMUX_TERMINAL_LIFECYCLE_ID:-}\" --session-id \"$wmux_ssh_attach_session_id\" --lifecycle-id \"$wmux_ssh_attach_lifecycle_id\" >/dev/null 2>&1 || true; }",
            "wmux_ssh_attach_signal_exit() { wmux_ssh_attach_signal_status=\"$1\"; wmux_ssh_attach_signal_name=\"$2\"; if [ -n \"${wmux_ssh_attach_auth_pid:-}\" ]; then wmux_ssh_terminate_auth_process_tree \"$wmux_ssh_attach_auth_pid\" \"$$\" 1 \"${wmux_ssh_attach_auth_event_token:-}\"; wait \"$wmux_ssh_attach_auth_pid\" 2>/dev/null || true; wmux_ssh_attach_auth_pid=; \(backoffBuilder.signalHandlerBranches) elif [ \"${wmux_ssh_attach_auth_launching:-0}\" = 1 ]; then wmux_ssh_attach_pending_signal=\"$wmux_ssh_attach_signal_status\"; wmux_ssh_attach_pending_signal_name=\"$wmux_ssh_attach_signal_name\"; return; fi; wmux_ssh_attach_restore_terminal; trap - EXIT HUP INT TERM; wmux_ssh_attach_lifecycle_end; exit \"$wmux_ssh_attach_signal_status\"; }",
            "trap 'wmux_ssh_attach_lifecycle_end' EXIT",
            "trap 'wmux_ssh_attach_signal_exit 129 HUP' HUP",
            "trap 'wmux_ssh_attach_signal_exit 130 INT' INT",
            "trap 'wmux_ssh_attach_signal_exit 143 TERM' TERM",
        ]
        let requireExistingFlag = requireExisting ? " --require-existing" : ""
        let commandB64Flag = normalized(remoteCommand).map {
            " --command-b64 \(shellQuote(Data($0.utf8).base64EncodedString()))"
        } ?? ""
        let attachCommand = "\"$wmux_ssh_attach_cli\" --socket \"$WMUX_SOCKET_PATH\" ssh-pty-attach --wait\(requireExistingFlag) --workspace \"$WMUX_WORKSPACE_ID\" --session-id \"$wmux_ssh_attach_session_id\" --lifecycle-id \"$wmux_ssh_attach_lifecycle_id\" --attachment-id \"${WMUX_SURFACE_ID:-}\"\(commandB64Flag)"
        lines += [
            "wmux_ssh_attach_register_attempt() { wmux_ssh_attach_launch_payload=\"{\\\"workspace_id\\\":\\\"$WMUX_WORKSPACE_ID\\\",\\\"surface_id\\\":\\\"${WMUX_SURFACE_ID:-}\\\",\\\"terminal_lifecycle_id\\\":\\\"${WMUX_TERMINAL_LIFECYCLE_ID:-}\\\",\\\"attempt_id\\\":\\\"$WMUX_SSH_ATTEMPT_ID\\\"}\"; WMUXTERM_CLI_RESPONSE_TIMEOUT_SEC=2 \"$wmux_ssh_attach_cli\" --socket \"$WMUX_SOCKET_PATH\" rpc workspace.remote.terminal_session_launching \"$wmux_ssh_attach_launch_payload\" >/dev/null 2>&1; }",
        ] + SSHPTYAttachRetryScriptBuilder().launchRegistrationRetryLines(functionPrefix: "wmux_ssh_attach") + [
            "wmux_ssh_attach_attempt() { wmux_ssh_attach_begin_attempt || return \"$?\"; \(attachCommand); }",
        ]
        lines += SSHPTYAttachRetryScriptBuilder().lines(
            command: "wmux_ssh_attach_attempt",
            reauthenticates: foregroundAuth != nil
        )
        return "/bin/sh -c \(shellQuote(lines.joined(separator: "\n")))"
    }

    static func restoredRemoteShellCommand(
        relayPort: Int,
        initialCommand: String? = nil,
        configuredRemoteCommand: String? = nil
    ) -> String {
        RemoteInteractiveShellBootstrapBuilder.script(
            remoteRelayPort: relayPort,
            shellFeatures: RemoteInteractiveShellBootstrapBuilder.shellFeatures(),
            initialCommand: initialCommand,
            configuredRemoteCommand: configuredRemoteCommand,
            bundledZshIntegration: RemoteInteractiveShellBootstrapBuilder.bundledShellIntegrationScript(named: "wmux-zsh-integration.zsh"),
            bundledBashIntegration: RemoteInteractiveShellBootstrapBuilder.bundledShellIntegrationScript(named: "wmux-bash-integration.bash"),
            bundledFishIntegration: RemoteInteractiveShellBootstrapBuilder.bundledShellIntegrationScript(named: "fish/config.fish"),
            protectsFromHangup: true
        )
    }

    private static func foregroundAuthLines(_ auth: ForegroundAuth) -> [String] {
        let readinessInsideResolvedLock =
            foregroundAuthenticationReadyShellLines(
                includeResolvedControlPath: true,
                requireSuccess: true,
                cliVariable: "WMUX_SSH_ATTACH_CLI"
            )
        let (sshCommand, reportsReadiness) =
            sshForegroundAuthCommand(
                auth,
                successShellLines: readinessInsideResolvedLock
            )
        var lines = [
            "wmux_ssh_attach_foreground_auth() {",
            "  \(sshCommand)",
            "wmux_ssh_auth_status=$?",
            "  if [ \"$wmux_ssh_auth_status\" -ne 0 ]; then return \"$wmux_ssh_auth_status\"; fi",
        ]
        if !reportsReadiness {
            lines.append("wmux_ssh_auth_token=\"$wmux_ssh_attach_auth_token\";")
            lines += foregroundAuthenticationReadyShellLines(
                includeResolvedControlPath: false,
                requireSuccess: false,
                cliVariable: "wmux_ssh_attach_cli"
            )
        }
        if let postAuthenticationCommand = normalized(auth.postAuthenticationCommand) {
            lines += [
                "  \(postAuthenticationCommand)",
                "  wmux_ssh_post_auth_status=$?",
                "  if [ \"$wmux_ssh_post_auth_status\" -ne 0 ]; then return \"$wmux_ssh_post_auth_status\"; fi",
                "  unset wmux_ssh_post_auth_status",
            ]
        }
        lines += [
            "unset wmux_ssh_auth_status",
            "}",
        ]
        return lines
    }

    private static func sshForegroundAuthCommand(
        _ auth: ForegroundAuth,
        successShellLines: [String]
    ) -> (command: String, reportsReadiness: Bool) {
        let sharingOptions = SSHConnectionSharingOptions()
        var arguments = ["/usr/bin/ssh"]
        let options = SSHAgentSocketResolver().removingOptions(
            named: "RemoteCommand",
            from: sharingOptions.mergingDefaults(
                into: auth.sshOptions,
                routeSensitiveOptions: (auth.identityFile.map { ["IdentityFile=\($0)"] } ?? [])
                    + auth.routeSensitivity.markerOptions,
                routeIdentifier: {
                    guard case .identified(let identifier) = auth.routeSensitivity else { return nil }
                    return identifier
                }()
            )
        )
        if !hasSSHOptionKey(options, key: "ConnectTimeout") {
            arguments += ["-o", "ConnectTimeout=6"]
        }
        if !hasSSHOptionKey(options, key: "ServerAliveInterval") {
            arguments += ["-o", "ServerAliveInterval=20"]
        }
        if !hasSSHOptionKey(options, key: "ServerAliveCountMax") {
            arguments += ["-o", "ServerAliveCountMax=2"]
        }
        if let port = auth.port {
            arguments += ["-p", String(port)]
        }
        if let identityFile = normalized(auth.identityFile) {
            arguments += ["-i", identityFile]
        }
        for option in options {
            arguments += ["-o", option]
        }
        // The command-line `true` below conflicts with a host-configured
        // RemoteCommand unless overridden (issue #7246).
        arguments += SSHHostConfiguredRemoteCommand().overrideArguments
        let preflight = sharingOptions.controlPathPreflightShellFunction(
            sshArguments: arguments,
            destination: auth.destination,
            options: options
        )
        let resolvedAuthenticationLockLines =
            resolvedControlMasterAuthenticationLockLines(
                sharingOptions: sharingOptions,
                sshArguments: arguments,
                destination: auth.destination,
                options: options
            )
        arguments += ["-T", "--", auth.destination, "true"]
        let command = arguments.map(shellQuote).joined(separator: " ")
        guard let lockPath = sharingOptions.foregroundAuthenticationLockPath(
            destination: auth.destination,
            port: auth.port,
            options: options
        ) else {
            return (
                SSHForegroundAuthenticationRetryPolicy()
                    .classifyingTransientFailure(in: command),
                false
            )
        }
        let inFlightPath = lockPath + ".inflight"
        var lockedCommand = SSHForegroundAuthenticationLaunch(token: auth.token)
            .tokenLoadShellLines(into: "wmux_ssh_auth_token")
        lockedCommand += [
            "umask 077",
            "wmux_ssh_auth_inflight_path=\(shellQuote(inFlightPath))",
            "wmux_ssh_auth_lock_path=\(shellQuote(lockPath))",
            "printf '%s\\n' \"$$\" > \"$wmux_ssh_auth_inflight_path\" || exit 255",
            "wmux_ssh_clear_auth_inflight() { if [ \"$(/bin/cat -- \"$wmux_ssh_auth_inflight_path\" 2>/dev/null || true)\" = \"$$\" ]; then /bin/rm -f -- \"$wmux_ssh_auth_inflight_path\" 2>/dev/null || true; fi; }",
            "trap 'wmux_ssh_clear_auth_inflight' EXIT",
            "trap 'wmux_ssh_clear_auth_inflight; exit 129' HUP",
            "trap 'wmux_ssh_clear_auth_inflight; exit 130' INT",
            "trap 'wmux_ssh_clear_auth_inflight; exit 143' TERM",
            ": >> \"$wmux_ssh_auth_lock_path\" || exit 255",
            "zmodload zsh/system || exit 255",
            "zsystem flock -t 45 -e -f wmux_ssh_auth_lock_fd \"$wmux_ssh_auth_lock_path\" || exit 255",
        ]
        lockedCommand += resolvedAuthenticationLockLines
        lockedCommand += [
            preflight,
            preflight == nil ? nil : "wmux_ssh_preflight_control_path",
            "command \(command)",
            "wmux_ssh_auth_status=$?",
            "if [ \"$wmux_ssh_auth_status\" -ne 0 ]; then exit \"$wmux_ssh_auth_status\"; fi",
        ].compactMap { $0 }
        lockedCommand += successShellLines
        lockedCommand += sharingOptions.successfulForegroundAuthenticationCleanupShellLines()
        lockedCommand.append("exit 0")
        let classifiedCommand = SSHForegroundAuthenticationRetryPolicy()
            .classifyingTransientFailure(in: lockedCommand.joined(separator: "\n"))
        let tokenEnvironment = SSHForegroundAuthenticationLaunch
            .environmentAssignment(from: "wmux_ssh_attach_auth_token")
        return (
            "\(tokenEnvironment) WMUX_SSH_ATTACH_CLI=\"$wmux_ssh_attach_cli\" \(classifiedCommand)",
            true
        )
    }

    private static func foregroundAuthenticationReadyShellLines(
        includeResolvedControlPath: Bool,
        requireSuccess: Bool,
        cliVariable: String
    ) -> [String] {
        SSHForegroundAuthenticationLaunch.readyShellLines(
            tokenVariable: "wmux_ssh_auth_token",
            payloadVariable: "wmux_ssh_auth_payload",
            cliVariable: cliVariable,
            socketVariable: "WMUX_SOCKET_PATH",
            controlPathVariable: includeResolvedControlPath
                ? "wmux_ssh_resolved_control_path"
                : nil,
            requireSuccess: requireSuccess
        )
    }

    private static func resolvedControlMasterAuthenticationLockLines(
        sharingOptions: SSHConnectionSharingOptions,
        sshArguments: [String],
        destination: String,
        options: [String]
    ) -> [String] {
        guard sharingOptions.cmuxOwnedControlPath(in: options) != nil,
              let socketPattern = sharingOptions.resolvedControlPathShellPattern else {
            return []
        }
        let sshPrefix = sshArguments.map(shellQuote).joined(separator: " ")
        let quotedDestination = shellQuote(destination)
        let lockPrefix = URL(
            fileURLWithPath: sharingOptions.controlMasterLockDirectoryPath,
            isDirectory: true
        )
        .appendingPathComponent(
            "wmux-ssh-\(sharingOptions.userID)-resolved-auth-",
            isDirectory: false
        )
        .path
        return [
            #"wmux_ssh_resolved_control_path="$(command \#(sshPrefix) -G \#(quotedDestination) 2>/dev/null | awk 'tolower($1) == "controlpath" { $1 = ""; sub(/^[[:space:]]+/, ""); print; exit }')" "#,
            "case \"$wmux_ssh_resolved_control_path\" in",
            "  \(socketPattern)) ;;",
            "  *) exit 255 ;;",
            "esac",
            "wmux_ssh_resolved_control_basename=\"${wmux_ssh_resolved_control_path##*/}\"",
            "case \"$wmux_ssh_resolved_control_basename\" in ''|*[!A-Za-z0-9._-]*) exit 255 ;; esac",
            "wmux_ssh_resolved_auth_lock_path=\(shellQuote(lockPrefix))\"$wmux_ssh_resolved_control_basename.lock\"",
            ": >> \"$wmux_ssh_resolved_auth_lock_path\" || exit 255",
            "zsystem flock -t 45 -e -f wmux_ssh_resolved_auth_lock_fd \"$wmux_ssh_resolved_auth_lock_path\" || exit 255",
        ]
    }

    static func sshOptionsWithRestoreControlDefaults(_ options: [String], relayPort: Int? = nil) -> [String] {
        _ = relayPort
        return SSHConnectionSharingOptions().mergingDefaults(into: options)
    }

    static func sshOptionsSupportReusableForegroundAuth(_ options: [String]) -> Bool {
        guard !hasSSHOptionKey(options, key: "LocalCommand"),
              !hasSSHOptionKey(options, key: "PermitLocalCommand") else {
            return false
        }

        guard let controlPath = sshOptionValue(named: "ControlPath", in: options),
              !controlPath.isEmpty,
              controlPath.lowercased() != "none" else {
            return false
        }

        if sshOptionValueIsDisabled(sshOptionValue(named: "ControlMaster", in: options)) {
            return false
        }

        return !sshOptionValueIsDisabled(
            sshOptionValue(named: "ControlPersist", in: options),
            zeroIsDisabled: false
        )
    }

    private static func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func hasSSHOptionKey(_ options: [String], key: String) -> Bool {
        SSHAgentSocketResolver().hasOptionKey(options, key: key)
    }

    private static func sshOptionValue(named name: String, in options: [String]) -> String? {
        SSHAgentSocketResolver().optionValue(named: name, in: options)
    }

    private static func sshOptionValueIsDisabled(_ rawValue: String?, zeroIsDisabled: Bool = true) -> Bool {
        guard let normalized = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return false
        }
        return ["no", "false", "off"].contains(normalized) || (zeroIsDisabled && normalized == "0")
    }

    private static func shellQuote(_ value: String) -> String {
        value.posixShellWord
    }
}
