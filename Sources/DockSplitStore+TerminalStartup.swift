import Foundation

extension DockSplitStore {
    static func resolvedWorkingDirectory(_ cwd: String?, baseDirectory: String) -> String {
        guard let cwd, !cwd.isEmpty else { return baseDirectory }
        if cwd.hasPrefix("/") {
            return cwd
        }
        return (baseDirectory as NSString).appendingPathComponent(cwd)
    }

    static func shellStartupScript(command: String, workingDirectory: String) -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent(
            "wmux-dock-control-\(UUID().uuidString.lowercased()).sh"
        )
        let encodedCommand = Data(command.utf8).base64EncodedString()
        let encodedWorkingDirectory = Data(workingDirectory.utf8).base64EncodedString()
        let body = """
        #!/bin/sh
        wmux_dock_decode() { printf '%s' "$1" | base64 --decode 2>/dev/null || printf '%s' "$1" | base64 -D 2>/dev/null; }
        wmux_dock_login_shell() {
          wmux_dock_user="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
          wmux_dock_ds_shell="$(dscl . -read "/Users/$wmux_dock_user" UserShell 2>/dev/null | awk '{print $2; exit}')"
          if [ -n "$wmux_dock_ds_shell" ] && [ -x "$wmux_dock_ds_shell" ]; then printf '%s\\n' "$wmux_dock_ds_shell"
          elif [ -n "${SHELL:-}" ] && [ -x "${SHELL:-}" ]; then printf '%s\\n' "$SHELL"
          else printf '%s\\n' /bin/sh; fi
        }
        wmux_dock_command="$(wmux_dock_decode '\(encodedCommand)')"
        wmux_dock_working_directory="$(wmux_dock_decode '\(encodedWorkingDirectory)')"
        wmux_dock_shell="$(wmux_dock_login_shell)"
        wmux_dock_bundle_bin=""
        if [ -n "${WMUX_BUNDLED_CLI_PATH:-}" ]; then wmux_dock_bundle_bin="$(dirname "$WMUX_BUNDLED_CLI_PATH")"; fi
        export SHELL="$wmux_dock_shell"
        rm -f -- "$0" 2>/dev/null || true
        case "$(basename "$wmux_dock_shell")" in
          fish)
            WMUX_DOCK_BUNDLE_BIN="$wmux_dock_bundle_bin" WMUX_DOCK_START_COMMAND="$wmux_dock_command" WMUX_DOCK_START_DIRECTORY="$wmux_dock_working_directory" "$wmux_dock_shell" -l -c 'if test -n "$WMUX_DOCK_BUNDLE_BIN"; and not contains -- "$WMUX_DOCK_BUNDLE_BIN" $PATH; set -gx PATH "$WMUX_DOCK_BUNDLE_BIN" $PATH; end; if test -n "$WMUX_DOCK_START_DIRECTORY"; cd "$WMUX_DOCK_START_DIRECTORY"; end; eval "$WMUX_DOCK_START_COMMAND"'
            ;;
          *) WMUX_DOCK_BUNDLE_BIN="$wmux_dock_bundle_bin" WMUX_DOCK_START_COMMAND="$wmux_dock_command" WMUX_DOCK_START_DIRECTORY="$wmux_dock_working_directory" "$wmux_dock_shell" -lc 'if [ -n "${WMUX_DOCK_BUNDLE_BIN:-}" ]; then case ":${PATH:-}:" in *":$WMUX_DOCK_BUNDLE_BIN:"*) ;; *) PATH="$WMUX_DOCK_BUNDLE_BIN${PATH:+:$PATH}"; export PATH ;; esac; fi; cd "$WMUX_DOCK_START_DIRECTORY" 2>/dev/null || true; eval "$WMUX_DOCK_START_COMMAND"'
            ;;
        esac
        printf '\\n'
        exec "$wmux_dock_shell" -l
        """
        do {
            try body.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)
            return scriptURL.path
        } catch {
            return "/bin/sh"
        }
    }
}
