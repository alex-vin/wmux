import WmuxFoundation
import Foundation

extension WMUXCLI {
    func buildSSHStartupCommand(
        sshCommand: String,
        shellFeatures: String,
        remoteRelayPort: Int,
        isShellSnippet: Bool = false,
        passwordCredential: String? = nil,
        controlPathPreflightShellFunction: String? = nil,
        reconnectLimitDefault: Int = 20,
        launchScripts: SSHStartupLaunchScripts
    ) throws -> String {
        let script = buildSSHStartupScriptBody(
            sshCommand: sshCommand,
            shellFeatures: shellFeatures,
            remoteRelayPort: remoteRelayPort,
            isShellSnippet: isShellSnippet,
            passwordCredential: passwordCredential,
            controlPathPreflightShellFunction: controlPathPreflightShellFunction,
            oneTimeCommand: nil,
            reconnectLimitDefault: reconnectLimitDefault
        )
        return try writeSSHStartupScript(script, remoteRelayPort: remoteRelayPort, launchScripts: launchScripts)
    }

    func buildReusableSSHStartupCommand(
        sshCommand: String,
        shellFeatures: String,
        remoteRelayPort: Int,
        isShellSnippet: Bool = false,
        passwordCredential: String? = nil,
        controlPathPreflightShellFunction: String? = nil,
        oneTimeCommand: String? = nil,
        reconnectLimitDefault: Int = 20
    ) -> String {
        // Reusable commands are persisted in workspace metadata and can be emitted over the socket API.
        // Short-lived credentials must stay in the one-shot launcher path only.
        let script = buildSSHStartupScriptBody(
            sshCommand: sshCommand,
            shellFeatures: shellFeatures,
            remoteRelayPort: remoteRelayPort,
            isShellSnippet: isShellSnippet,
            passwordCredential: nil,
            controlPathPreflightShellFunction: controlPathPreflightShellFunction,
            oneTimeCommand: oneTimeCommand,
            reconnectLimitDefault: reconnectLimitDefault
        )
        return reusableShellStartupCommand(
            scriptBody: script,
            tempPrefix: "wmux-ssh-startup"
        )
    }

    func sshAskpassExecShellScript(passwordCredential: String) -> String {
        let passwordB64 = Data(passwordCredential.utf8).base64EncodedString()
        return [
            "set -e",
            "wmux_ssh_askpass_dir=$(mktemp -d \"${TMPDIR:-/tmp}/wmux-ssh-askpass.XXXXXX\")",
            "wmux_ssh_askpass_file=\"$wmux_ssh_askpass_dir/password\"",
            "wmux_ssh_askpass_script=\"$wmux_ssh_askpass_dir/askpass\"",
            "wmux_ssh_expect_script=\"$wmux_ssh_askpass_dir/ssh-password.exp\"",
            "cleanup() { rm -rf \"$wmux_ssh_askpass_dir\"; }",
            "trap cleanup EXIT HUP INT TERM",
            "printf %s \(shellQuote(passwordB64)) | base64 -d > \"$wmux_ssh_askpass_file\" 2>/dev/null || printf %s \(shellQuote(passwordB64)) | base64 -D > \"$wmux_ssh_askpass_file\"",
            "chmod 600 \"$wmux_ssh_askpass_file\"",
            "if command -v expect >/dev/null 2>&1; then",
            "  cat > \"$wmux_ssh_expect_script\" <<'WMUX_EXPECT'",
            "set timeout 12",
            "set password_file $env(WMUX_SSH_ASKPASS_FILE)",
            "set fh [open $password_file r]",
            "set password [read $fh]",
            "close $fh",
            "set password [string trimright $password \"\\r\\n\"]",
            "set wmux_interactive_stdin [expr {[catch {exec /bin/sh -c {test -t 0}}] == 0}]",
            "log_user 0",
            "spawn {*}$argv",
            "proc wmux_rejected_password {} {",
            "  puts stderr {\\n[wmux] Cloud VM SSH credential was rejected; reconnecting.}",
            "  catch {close}",
            "  catch {wait}",
            "  exit 255",
            "}",
            "proc wmux_relay_session {} {",
            "  global wmux_interactive_stdin",
            "  set timeout -1",
            "  log_user 1",
            "  if {$wmux_interactive_stdin} {",
            "    interact",
            "    set status [wait]",
            "    exit [lindex $status 3]",
            "  }",
            "  expect { eof { set status [wait]; exit [lindex $status 3] } }",
            "}",
            "proc wmux_wait_after_password {} {",
            "  set timeout 2",
            "  expect {",
            "    -re \"(?i)permission denied\" { wmux_rejected_password }",
            "    -re \"(?i)password:\" { wmux_rejected_password }",
            "    timeout {",
            "      set wmux_buffer \"\"",
            "      catch { set wmux_buffer $expect_out(buffer) }",
            "      if {[regexp -nocase {(password:|permission denied)} $wmux_buffer]} { wmux_rejected_password }",
            "      if {[string length $wmux_buffer] > 0} { send_user -- $wmux_buffer }",
            "      wmux_relay_session",
            "    }",
            // A session that authenticates and ends inside this window still
            // owes the user its output: flush what expect buffered before exiting.
            "    eof {",
            "      catch { send_user -- $expect_out(buffer) }",
            "      set status [wait]",
            "      exit [lindex $status 3]",
            "    }",
            "  }",
            "}",
            "expect {",
            "  -re \"(?i)password:\" {",
            "    send -- \"$password\\r\"",
            "    wmux_wait_after_password",
            "  }",
            "  timeout {",
            "    puts stderr {\\n[wmux] Cloud VM SSH credential prompt timed out; reconnecting.}",
            "    exit 255",
            "  }",
            "  eof { set status [wait]; exit [lindex $status 3] }",
            "}",
            "set status [wait]",
            "exit [lindex $status 3]",
            "WMUX_EXPECT",
            "  chmod 700 \"$wmux_ssh_expect_script\"",
            "  export WMUX_SSH_ASKPASS_FILE=\"$wmux_ssh_askpass_file\"",
            "  set +e",
            "  expect \"$wmux_ssh_expect_script\" \"$@\"",
            "  wmux_ssh_status=$?",
            "  exit \"$wmux_ssh_status\"",
            "fi",
            "printf '%s\\n' '#!/bin/sh' 'cat \"$WMUX_SSH_ASKPASS_FILE\"' > \"$wmux_ssh_askpass_script\"",
            "chmod 700 \"$wmux_ssh_askpass_script\"",
            "export WMUX_SSH_ASKPASS_FILE=\"$wmux_ssh_askpass_file\"",
            "export SSH_ASKPASS=\"$wmux_ssh_askpass_script\"",
            "export SSH_ASKPASS_REQUIRE=force",
            "export DISPLAY=\"${DISPLAY:-wmux}\"",
            "set +e",
            "\"$@\"",
            "wmux_ssh_status=$?",
            "exit \"$wmux_ssh_status\"",
        ].joined(separator: "\n")
    }
    func sshAskpassExecShellScript(passwordFilePath: String, cleanupDirectory: String) -> String {
        [
            "set -e",
            "wmux_ssh_askpass_dir=\(shellQuote(cleanupDirectory))",
            "wmux_ssh_askpass_file=\(shellQuote(passwordFilePath))",
            "wmux_ssh_askpass_script=\"$wmux_ssh_askpass_dir/askpass\"",
            "wmux_ssh_expect_script=\"$wmux_ssh_askpass_dir/ssh-password.exp\"",
            "cleanup() { rm -rf \"$wmux_ssh_askpass_dir\"; }",
            "trap cleanup EXIT HUP INT TERM",
            "chmod 600 \"$wmux_ssh_askpass_file\"",
            "if command -v expect >/dev/null 2>&1; then",
            "  cat > \"$wmux_ssh_expect_script\" <<'WMUX_EXPECT'",
            "set timeout 12",
            "set password_file $env(WMUX_SSH_ASKPASS_FILE)",
            "set fh [open $password_file r]",
            "set password [read $fh]",
            "close $fh",
            "set password [string trimright $password \"\\r\\n\"]",
            "set wmux_interactive_stdin [expr {[catch {exec /bin/sh -c {test -t 0}}] == 0}]",
            "log_user 0",
            "spawn {*}$argv",
            "proc wmux_rejected_password {} {",
            "  puts stderr {\\n[wmux] Cloud VM SSH credential was rejected; reconnecting.}",
            "  catch {close}",
            "  catch {wait}",
            "  exit 255",
            "}",
            "proc wmux_relay_session {} {",
            "  global wmux_interactive_stdin",
            "  set timeout -1",
            "  log_user 1",
            "  if {$wmux_interactive_stdin} {",
            "    interact",
            "    set status [wait]",
            "    exit [lindex $status 3]",
            "  }",
            "  expect { eof { set status [wait]; exit [lindex $status 3] } }",
            "}",
            "proc wmux_wait_after_password {} {",
            "  set timeout 2",
            "  expect {",
            "    -re \"(?i)permission denied\" { wmux_rejected_password }",
            "    -re \"(?i)password:\" { wmux_rejected_password }",
            "    timeout {",
            "      set wmux_buffer \"\"",
            "      catch { set wmux_buffer $expect_out(buffer) }",
            "      if {[regexp -nocase {(password:|permission denied)} $wmux_buffer]} { wmux_rejected_password }",
            "      if {[string length $wmux_buffer] > 0} { send_user -- $wmux_buffer }",
            "      wmux_relay_session",
            "    }",
            // A session that authenticates and ends inside this window still
            // owes the user its output: flush what expect buffered before exiting.
            "    eof {",
            "      catch { send_user -- $expect_out(buffer) }",
            "      set status [wait]",
            "      exit [lindex $status 3]",
            "    }",
            "  }",
            "}",
            "expect {",
            "  -re \"(?i)password:\" {",
            "    send -- \"$password\\r\"",
            "    wmux_wait_after_password",
            "  }",
            "  timeout {",
            "    puts stderr {\\n[wmux] Cloud VM SSH credential prompt timed out; reconnecting.}",
            "    exit 255",
            "  }",
            "  eof { set status [wait]; exit [lindex $status 3] }",
            "}",
            "set status [wait]",
            "exit [lindex $status 3]",
            "WMUX_EXPECT",
            "  chmod 700 \"$wmux_ssh_expect_script\"",
            "  export WMUX_SSH_ASKPASS_FILE=\"$wmux_ssh_askpass_file\"",
            "  set +e",
            "  expect \"$wmux_ssh_expect_script\" \"$@\"",
            "  wmux_ssh_status=$?",
            "  exit \"$wmux_ssh_status\"",
            "fi",
            "printf '%s\\n' '#!/bin/sh' 'cat \"$WMUX_SSH_ASKPASS_FILE\"' > \"$wmux_ssh_askpass_script\"",
            "chmod 700 \"$wmux_ssh_askpass_script\"",
            "export WMUX_SSH_ASKPASS_FILE=\"$wmux_ssh_askpass_file\"",
            "export SSH_ASKPASS=\"$wmux_ssh_askpass_script\"",
            "export SSH_ASKPASS_REQUIRE=force",
            "export DISPLAY=\"${DISPLAY:-wmux}\"",
            "set +e",
            "\"$@\"",
            "wmux_ssh_status=$?",
            "exit \"$wmux_ssh_status\"",
        ].joined(separator: "\n")
    }
    private func buildSSHStartupScriptBody(
        sshCommand: String,
        shellFeatures: String,
        remoteRelayPort: Int,
        isShellSnippet: Bool,
        passwordCredential: String?,
        controlPathPreflightShellFunction: String?,
        oneTimeCommand: String?,
        reconnectLimitDefault: Int
    ) -> String {
        let trimmedFeatures = shellFeatures.trimmingCharacters(in: .whitespacesAndNewlines)
        let shellFeaturesBootstrap: String = trimmedFeatures.isEmpty
            ? ""
            : "export GHOSTTY_SHELL_FEATURES=\(shellQuote(trimmedFeatures))"
        let lifecycleCleanup = buildSSHSessionEndShellCommand(remoteRelayPort: remoteRelayPort)
        let lifecycleLaunching = remoteRelayPort > 0
            ? buildSSHTerminalSessionLaunchingShellCommand()
            : ":"
        let trimmedControlPathPreflight = controlPathPreflightShellFunction?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOneTimeCommand = oneTimeCommand?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasOneTimeCommand = trimmedOneTimeCommand?.isEmpty == false
        let authRetryPolicy = SSHForegroundAuthenticationRetryPolicy()
        let authenticationResult = authRetryPolicy.persistentAuthenticationResultShellLine(
            variablePrefix: "wmux_ssh",
            terminalFailureCommand: "break"
        )
        let backoffBuilder = SSHRetryBackoffScriptBuilder(context: .startup)
        let terminalModeReset = shellQuote(SSHTerminalModeResetSequence().shellPrintfFormat)
        let reconnectNote = shellQuote(sshAutoReconnectNoteFormat())
        let terminalExitPrompt = shellQuote(sshTerminalExitPromptFormat())
        let reconnectRecoveredNote = shellQuote(sshAutoReconnectRecoveredNoteFormat())
        let launchAcknowledgementTimeoutNote = shellQuote(String(
            localized: "cli.sshPtyAttach.launchAcknowledgementTimeoutRetry",
            defaultValue: "[wmux] wmux did not acknowledge the SSH launch; retrying %s in %ss.",
            bundle: CLIExecutableLocator.enclosingAppBundle() ?? .main
        ))
        let terminalExitPromptCommand = [
            shellQuote(resolvedExecutableURL()?.path ?? (args.first ?? "wmux")),
            "__ssh-terminal-exit-prompt",
        ].joined(separator: " ")
        var scriptLines: [String] = []
        if !shellFeaturesBootstrap.isEmpty {
            scriptLines.append(shellFeaturesBootstrap)
        }
        if let passwordCredential, !passwordCredential.isEmpty {
            let passwordB64 = Data(passwordCredential.utf8).base64EncodedString()
            scriptLines += [
                "wmux_ssh_askpass_dir=$(mktemp -d \"${TMPDIR:-/tmp}/wmux-ssh-askpass.XXXXXX\") || exit 1",
                "wmux_ssh_askpass_file=\"$wmux_ssh_askpass_dir/password\"",
                "wmux_ssh_askpass_script=\"$wmux_ssh_askpass_dir/askpass\"",
                "printf %s \(shellQuote(passwordB64)) | base64 -d > \"$wmux_ssh_askpass_file\" 2>/dev/null || printf %s \(shellQuote(passwordB64)) | base64 -D > \"$wmux_ssh_askpass_file\" || exit 1",
                "chmod 600 \"$wmux_ssh_askpass_file\"",
                "printf '%s\\n' '#!/bin/sh' 'cat \"$WMUX_SSH_ASKPASS_FILE\"' > \"$wmux_ssh_askpass_script\"",
                "chmod 700 \"$wmux_ssh_askpass_script\"",
                "export WMUX_SSH_ASKPASS_FILE=\"$wmux_ssh_askpass_file\"",
                "export SSH_ASKPASS=\"$wmux_ssh_askpass_script\"",
                "export SSH_ASKPASS_REQUIRE=force",
                "export DISPLAY=\"${DISPLAY:-wmux}\"",
                "wmux_ssh_cleanup_password() { rm -rf \"$wmux_ssh_askpass_dir\" 2>/dev/null || true; }",
            ]
        } else {
            scriptLines.append("wmux_ssh_cleanup_password() { :; }")
        }
        if let trimmedControlPathPreflight, !trimmedControlPathPreflight.isEmpty {
            scriptLines.append(trimmedControlPathPreflight)
        }
        if let trimmedOneTimeCommand, !trimmedOneTimeCommand.isEmpty {
            scriptLines += ["wmux_ssh_foreground_auth() {", trimmedOneTimeCommand, "}"]
            scriptLines.append(authRetryPolicy.processTreeTerminationShellFunction())
        }
        let reconnectConfiguration = [
            "wmux_ssh_reconnect_limit=\"${WMUX_SSH_RECONNECT_LIMIT:-\(max(0, reconnectLimitDefault))}\"",
            "case \"$wmux_ssh_reconnect_limit\" in ''|*[!0-9]*) wmux_ssh_reconnect_limit=20 ;; esac",
            "wmux_ssh_reconnect_delay=\"${WMUX_SSH_RECONNECT_DELAY_SECONDS:-2}\"",
            "case \"$wmux_ssh_reconnect_delay\" in ''|*[!0-9]*) wmux_ssh_reconnect_delay=2 ;; esac",
            "if [ \"$wmux_ssh_reconnect_delay\" -lt 1 ]; then wmux_ssh_reconnect_delay=2; fi",
        ]
        scriptLines += [
            "rm -f -- \"$0\" 2>/dev/null || true",
            "WMUX_SSH_SESSION_ENDED=0",
            "WMUX_SSH_STARTUP_PID=$$",
            "export WMUX_SSH_STARTUP_PID",
        ]
        scriptLines += reconnectConfiguration
        scriptLines += [
            "wmux_ssh_retry=0",
            "wmux_ssh_auth_retry_limit=\(authRetryPolicy.maximumConsecutiveTransientFailures); wmux_ssh_auth_retry=0",
            "wmux_ssh_auth_succeeded=0",
            // Initial transient foreground-auth failures are a reconnect phase, so boot-time outages share this loop.
            "wmux_ssh_reauth_required=\(hasOneTimeCommand ? 1 : 0)",
            "WMUX_SSH_CHILD_PID=; WMUX_SSH_AUTH_PID=; WMUX_SSH_PENDING_SIGNAL=; WMUX_SSH_PENDING_SIGNAL_NAME=",
        ]
        scriptLines += backoffBuilder.stateInitializationLines
        scriptLines += [
            "wmux_ssh_note() { if [ -t 2 ]; then printf \"$@\" >&2 || true; fi; }",
            "wmux_ssh_reset_terminal_modes() { if [ -t 2 ]; then printf \(terminalModeReset) >&2 || true; fi; }",
            "wmux_ssh_register_attempt() { \(lifecycleLaunching); }",
        ] + SSHPTYAttachRetryScriptBuilder().launchRegistrationRetryLines(functionPrefix: "wmux_ssh") + [
            "wmux_ssh_session_end() { if [ \"${WMUX_SSH_SESSION_ENDED:-0}\" = 1 ]; then return; fi; WMUX_SSH_SESSION_ENDED=1; wmux_ssh_cleanup_password; \(lifecycleCleanup); }",
            "wmux_ssh_retire_for_signal() { wmux_ssh_signal_status=\"$1\"; WMUX_SSH_SESSION_ENDED=1; wmux_ssh_cleanup_password; trap - EXIT HUP INT TERM; exit \"$wmux_ssh_signal_status\"; }",
            "wmux_ssh_signal_exit() { wmux_ssh_signal_status=\"$1\"; wmux_ssh_signal_name=\"$2\"; if [ -n \"${WMUX_SSH_AUTH_PID:-}\" ]; then wmux_ssh_terminate_auth_process_tree \"$WMUX_SSH_AUTH_PID\" \"$WMUX_SSH_STARTUP_PID\"; wait \"$WMUX_SSH_AUTH_PID\" 2>/dev/null || true; WMUX_SSH_AUTH_PID=; \(backoffBuilder.signalHandlerBranches) elif [ -z \"${WMUX_SSH_CHILD_PID:-}\" ]; then WMUX_SSH_PENDING_SIGNAL=\"$wmux_ssh_signal_status\"; WMUX_SSH_PENDING_SIGNAL_NAME=\"$wmux_ssh_signal_name\"; return; fi; wmux_ssh_retire_for_signal \"$wmux_ssh_signal_status\"; }",
            "trap 'wmux_ssh_session_end' EXIT",
            "trap 'wmux_ssh_signal_exit 129 HUP' HUP",
            "trap 'wmux_ssh_signal_exit 130 INT' INT",
            "trap 'wmux_ssh_signal_exit 143 TERM' TERM",
        ]
        scriptLines += [
            "while :; do",
            "  if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_retire_for_signal \"$WMUX_SSH_PENDING_SIGNAL\"; fi",
        ]
        if hasOneTimeCommand {
            scriptLines.append("  if [ \"$wmux_ssh_reauth_required\" -eq 1 ]; then")
            scriptLines += ["    ( wmux_ssh_foreground_auth ) <&0 &", "    WMUX_SSH_AUTH_PID=$!; if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_signal_exit \"$WMUX_SSH_PENDING_SIGNAL\" \"${WMUX_SSH_PENDING_SIGNAL_NAME:-TERM}\"; fi; wait \"$WMUX_SSH_AUTH_PID\"; wmux_ssh_status=$?; WMUX_SSH_AUTH_PID=; case \"$wmux_ssh_status\" in 129|130|143) wmux_ssh_retire_for_signal \"$wmux_ssh_status\" ;; esac; if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_session_end; trap - EXIT HUP INT TERM; exit \"$WMUX_SSH_PENDING_SIGNAL\"; fi", "    \(authenticationResult)", "  fi", "  if [ \"$wmux_ssh_reauth_required\" -eq 0 ]; then"]
        }
        if let trimmedControlPathPreflight, !trimmedControlPathPreflight.isEmpty,
           !hasOneTimeCommand {
            scriptLines.append("  wmux_ssh_preflight_control_path")
        }
        scriptLines += [
            "  wmux_ssh_begin_attempt",
            "  wmux_ssh_registration_status=$?",
            "  if [ \"$wmux_ssh_registration_status\" -ne 0 ] && [ \"$wmux_ssh_registration_status\" -ne \(SSHPTYAttachExitCode.launchAcknowledgementTimedOut.rawValue) ]; then exit \"$wmux_ssh_registration_status\"; fi",
            "  if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_retire_for_signal \"$WMUX_SSH_PENDING_SIGNAL\"; fi",
        ]
        if isShellSnippet {
            scriptLines += [
                "  if [ \"$wmux_ssh_registration_status\" -eq 0 ]; then",
                "    (",
                "      \(sshCommand)",
                "    ) <&0 &",
                "  fi",
            ]
        } else {
            scriptLines += [
                "  if [ \"$wmux_ssh_registration_status\" -eq 0 ]; then",
                "    command \(sshCommand) <&0 &",
                "  fi",
            ]
        }
        scriptLines += [
            "  WMUX_SSH_CHILD_PID=",
            "  if [ \"$wmux_ssh_registration_status\" -eq 0 ]; then WMUX_SSH_CHILD_PID=$!; fi",
            "  if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_signal_exit \"$WMUX_SSH_PENDING_SIGNAL\"; fi",
            "  if [ \"$wmux_ssh_registration_status\" -eq 0 ]; then wait \"$WMUX_SSH_CHILD_PID\"; wmux_ssh_status=$?; else wmux_ssh_status=\"$wmux_ssh_registration_status\"; fi",
            "  WMUX_SSH_CHILD_PID=",
            "  if [ \"$wmux_ssh_status\" -eq \(SSHPTYAttachExitCode.launchAcknowledgementTimedOut.rawValue) ] && [ \"$wmux_ssh_registration_status\" -eq 0 ]; then break; fi",
            "  if [ \"$wmux_ssh_status\" -eq 0 ]; then if [ \"$wmux_ssh_retry\" -gt 0 ]; then wmux_ssh_note \"$(printf \(reconnectRecoveredNote) \"$wmux_ssh_retry\" \"$wmux_ssh_reconnect_limit\")\"; fi; break; fi",
            "  wmux_ssh_reset_terminal_modes",
            "  case \"$wmux_ssh_status\" in 255|\(SSHPTYAttachExitCode.launchAcknowledgementTimedOut.rawValue)) ;; *) break ;; esac",
        ]
        if hasOneTimeCommand {
            scriptLines += ["  if [ \"$wmux_ssh_status\" -eq 255 ]; then wmux_ssh_reauth_required=1; fi", "  fi"]
        }
        let retryLimitCondition =
            "  if [ \"$wmux_ssh_retry\" -ge \"$wmux_ssh_reconnect_limit\" ]; then break; fi"
        scriptLines.append(retryLimitCondition)
        scriptLines += [
            "  wmux_ssh_retry=$((wmux_ssh_retry + 1))",
            "  \(backoffBuilder.terminalInputModeResetLine)",
            "  if [ \"$wmux_ssh_status\" -eq \(SSHPTYAttachExitCode.launchAcknowledgementTimedOut.rawValue) ]; then wmux_ssh_note \(launchAcknowledgementTimeoutNote) \"$wmux_ssh_retry\" \"$wmux_ssh_reconnect_delay\"; else wmux_ssh_note \(reconnectNote) \"$wmux_ssh_status\" \"$wmux_ssh_retry\" \"$wmux_ssh_reconnect_limit\"; fi",
        ]
        scriptLines += backoffBuilder.waitLines
        scriptLines += [
            "  if [ -n \"${WMUX_SSH_PENDING_SIGNAL:-}\" ]; then wmux_ssh_session_end; trap - EXIT HUP INT TERM; exit \"$WMUX_SSH_PENDING_SIGNAL\"; fi",
            "done",
            "trap - EXIT HUP INT TERM",
            "wmux_ssh_session_end",
            "if [ \"$wmux_ssh_status\" -ne 0 ]; then",
            "  \(backoffBuilder.terminalInputModeResetLine)",
            "  wmux_ssh_prompt_tty_state=$(/bin/stty -g <&0 2>/dev/null || true)",
            "  wmux_ssh_prompt_restore_tty() { if [ -n \"${wmux_ssh_prompt_tty_state:-}\" ]; then /bin/stty \"$wmux_ssh_prompt_tty_state\" <&0 2>/dev/null || true; wmux_ssh_prompt_tty_state=; fi; }",
            "  wmux_ssh_prompt_signal_exit() { wmux_ssh_prompt_signal_status=\"$1\"; wmux_ssh_prompt_restore_tty; trap - EXIT HUP INT TERM; exit \"$wmux_ssh_prompt_signal_status\"; }",
            "  trap 'wmux_ssh_prompt_restore_tty' EXIT",
            "  trap 'wmux_ssh_prompt_signal_exit 129' HUP",
            "  trap 'wmux_ssh_prompt_signal_exit 130' INT",
            "  trap 'wmux_ssh_prompt_signal_exit 143' TERM",
            "  printf \(terminalExitPrompt) \"$wmux_ssh_status\" >&2 || true",
            "  if [ -t 0 ]; then \(terminalExitPromptCommand) <&0; else exec \(terminalExitPromptCommand) <&0; fi",
            "  wmux_ssh_prompt_restore_tty",
            "  trap - EXIT HUP INT TERM",
            "fi",
            "exit $wmux_ssh_status",
        ]
        return scriptLines.joined(separator: "\n")
    }
    private func writeSSHStartupScript(
        _ scriptBody: String,
        remoteRelayPort: Int,
        launchScripts: SSHStartupLaunchScripts
    ) throws -> String {
        let scriptURL = try launchScripts.write(scriptBody: scriptBody, remoteRelayPort: remoteRelayPort)
        return shellQuote(scriptURL.path)
    }
    private func reusableShellStartupCommand(
        scriptBody: String,
        tempPrefix: String
    ) -> String {
        let fullScript = "#!/bin/sh\n\(scriptBody)\n"
        let encodedScript = Data(fullScript.utf8).base64EncodedString()
        let encodedLiteral = shellQuote(encodedScript)
        let wrapper = [
            "wmux_tmp=$(mktemp \"${TMPDIR:-/tmp}/\(tempPrefix).XXXXXX\") || exit 1",
            "wmux_cleanup() { rm -f -- \"$wmux_tmp\" 2>/dev/null || true; }",
            "trap 'wmux_cleanup' EXIT HUP INT TERM",
            // Choose the decoder before writing the payload. Repeating the large
            // bootstrap for a fallback can push the launcher past macOS ARG_MAX.
            "if base64 -d </dev/null >/dev/null 2>&1; then wmux_decode_flag=-d; else wmux_decode_flag=-D; fi",
            "(printf %s \(encodedLiteral) | base64 \"$wmux_decode_flag\") > \"$wmux_tmp\" || exit 1",
            "chmod 700 \"$wmux_tmp\" >/dev/null 2>&1 || true",
            "/bin/sh \"$wmux_tmp\"",
            "wmux_status=$?",
            "trap - EXIT HUP INT TERM",
            "wmux_cleanup",
            "unset wmux_tmp wmux_decode_flag",
            "unset -f wmux_cleanup 2>/dev/null || true",
            "exit $wmux_status",
        ].joined(separator: "\n")
        return "/bin/sh -c \(shellQuote(wrapper))"
    }
    private func buildSSHSessionEndShellCommand(remoteRelayPort: Int) -> String {
        [
            "if [ -n \"${WMUX_BUNDLED_CLI_PATH:-}\" ]",
            "&& [ -x \"${WMUX_BUNDLED_CLI_PATH}\" ]",
            "&& [ -n \"${WMUX_SOCKET_PATH:-}\" ]",
            "&& [ -n \"${WMUX_WORKSPACE_ID:-}\" ]",
            "&& [ -n \"${WMUX_SURFACE_ID:-}\" ]; then",
            "\"${WMUX_BUNDLED_CLI_PATH}\" --socket \"${WMUX_SOCKET_PATH}\" ssh-session-end --relay-port \(remoteRelayPort) --workspace \"${WMUX_WORKSPACE_ID}\" --surface \"${WMUX_SURFACE_ID}\" --terminal-lifecycle-id \"${WMUX_TERMINAL_LIFECYCLE_ID:-}\" --session-id \"${WMUX_SSH_PTY_SESSION_ID:-}\" --lifecycle-id \"${WMUX_SSH_PTY_LIFECYCLE_ID:-}\" >/dev/null 2>&1 || true;",
            "elif command -v wmux >/dev/null 2>&1",
            "&& [ -n \"${WMUX_WORKSPACE_ID:-}\" ]",
            "&& [ -n \"${WMUX_SURFACE_ID:-}\" ]; then",
            "wmux ssh-session-end --relay-port \(remoteRelayPort) --workspace \"${WMUX_WORKSPACE_ID}\" --surface \"${WMUX_SURFACE_ID}\" --terminal-lifecycle-id \"${WMUX_TERMINAL_LIFECYCLE_ID:-}\" --session-id \"${WMUX_SSH_PTY_SESSION_ID:-}\" --lifecycle-id \"${WMUX_SSH_PTY_LIFECYCLE_ID:-}\" >/dev/null 2>&1 || true;",
            "fi",
        ].joined(separator: " ")
    }

    private func buildSSHTerminalSessionLaunchingShellCommand() -> String {
        let arguments =
            "rpc workspace.remote.terminal_session_launching " +
            "\"{\\\"workspace_id\\\":\\\"${WMUX_WORKSPACE_ID}\\\"," +
            "\\\"surface_id\\\":\\\"${WMUX_SURFACE_ID}\\\"," +
            "\\\"terminal_lifecycle_id\\\":\\\"${WMUX_TERMINAL_LIFECYCLE_ID}\\\"," +
            "\\\"attempt_id\\\":\\\"${WMUX_SSH_ATTEMPT_ID}\\\"}\""
        return [
            "if [ -n \"${WMUX_BUNDLED_CLI_PATH:-}\" ]",
            "&& [ -x \"${WMUX_BUNDLED_CLI_PATH}\" ]",
            "&& [ -n \"${WMUX_SOCKET_PATH:-}\" ]",
            "&& [ -n \"${WMUX_WORKSPACE_ID:-}\" ]",
            "&& [ -n \"${WMUX_SURFACE_ID:-}\" ]; then",
            "WMUXTERM_CLI_RESPONSE_TIMEOUT_SEC=2 \"${WMUX_BUNDLED_CLI_PATH}\" --socket \"${WMUX_SOCKET_PATH}\" \(arguments) >/dev/null 2>&1;",
            "elif command -v wmux >/dev/null 2>&1",
            "&& [ -n \"${WMUX_SOCKET_PATH:-}\" ]",
            "&& [ -n \"${WMUX_WORKSPACE_ID:-}\" ]",
            "&& [ -n \"${WMUX_SURFACE_ID:-}\" ]; then",
            "WMUXTERM_CLI_RESPONSE_TIMEOUT_SEC=2 wmux --socket \"${WMUX_SOCKET_PATH}\" \(arguments) >/dev/null 2>&1;",
            "else",
            "false;",
            "fi",
        ].joined(separator: " ")
    }
}
