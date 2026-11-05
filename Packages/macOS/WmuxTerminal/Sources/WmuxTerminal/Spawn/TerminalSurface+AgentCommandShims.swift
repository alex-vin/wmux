public import Foundation
import WmuxFoundation
public import WmuxTerminalCore

extension TerminalSurface {
    /// Writes every available bundled agent wrapper shim into one per-surface directory.
    ///
    /// Adding an agent to ``TerminalSurfaceAgentCommandShimDefinition/bundled``
    /// automatically gives it the same lifecycle, permissions, `PATH`, bundle-
    /// replacement fallback, and environment behavior as existing agents.
    ///
    /// - Parameters:
    ///   - wrapperDirectoryURL: The app bundle directory containing cmux's launch wrappers.
    ///   - surfaceId: The terminal surface that owns the generated shim directory.
    ///   - rootDirectory: The root under which the isolated shim directory is created. The
    ///     live app supplies a durable per-user cmux state directory; tests may use a temporary root.
    ///   - enabledCommands: Bundled agent commands that should receive a shim.
    ///   - hermesProfileAliasDirectoryURL: The Hermes-owned wrapper directory to inspect for profile aliases.
    ///   - fileManager: The filesystem implementation used for discovery and installation.
    /// - Returns: The installed shim set, or `nil` when no bundled wrapper can be installed.
    public static func installAgentCommandShimsIfPossible(
        wrapperDirectoryURL: URL?,
        surfaceId: UUID,
        rootDirectory: URL,
        enabledCommands: Set<TerminalSurfaceAgentCommand> = Set(TerminalSurfaceAgentCommand.allCases),
        hermesProfileAliasDirectoryURL: URL? = nil,
        computerUseSettingFileURL: URL? = nil,
        fileManager: FileManager = .default
    ) -> TerminalSurfaceAgentCommandShimSet? {
        guard let wrapperDirectoryURL = wrapperDirectoryURL?.standardizedFileURL else { return nil }
        let aliases = hermesProfileAliasDirectoryURL.map { aliasDirectoryURL in
            HermesProfileAliasResolver(
                wrapperDirectoryURL: aliasDirectoryURL,
                fileManager: fileManager
            ).resolve(excluding: reservedAgentCommandShimNames)
        } ?? []
        return installAgentCommandShimsIfPossible(
            wrapperDirectoryURL: wrapperDirectoryURL,
            surfaceId: surfaceId,
            rootDirectory: rootDirectory,
            enabledCommands: enabledCommands,
            hermesProfileAliases: aliases,
            computerUseSettingFileURL: computerUseSettingFileURL,
            fileManager: fileManager
        )
    }

    /// Writes bundled agent shims using a process-owned Hermes alias catalog.
    ///
    /// The catalog serializes concurrent restore requests and scans the shared
    /// Hermes wrapper directory only once per directory generation.
    ///
    /// - Parameters:
    ///   - wrapperDirectoryURL: The app bundle directory containing cmux's launch wrappers.
    ///   - surfaceId: The terminal surface that owns the generated shim directory.
    ///   - rootDirectory: The root under which the isolated shim directory is created. The
    ///     live app supplies a durable per-user cmux state directory; tests may use a temporary root.
    ///   - enabledCommands: Bundled agent commands that should receive a shim.
    ///   - hermesProfileAliasCatalog: The process-owned Hermes alias discovery cache.
    ///   - fileManager: The filesystem implementation used for shim installation.
    /// - Returns: The installed shim set, or `nil` when no bundled wrapper can be installed.
    public static func installAgentCommandShimsIfPossible(
        wrapperDirectoryURL: URL?,
        surfaceId: UUID,
        rootDirectory: URL,
        enabledCommands: Set<TerminalSurfaceAgentCommand> = Set(TerminalSurfaceAgentCommand.allCases),
        hermesProfileAliasCatalog: HermesProfileAliasCatalog,
        computerUseSettingFileURL: URL? = nil,
        fileManager: FileManager = .default
    ) async -> TerminalSurfaceAgentCommandShimSet? {
        guard let wrapperDirectoryURL = wrapperDirectoryURL?.standardizedFileURL else { return nil }
        let aliases = await hermesProfileAliasCatalog.aliases(
            excluding: reservedAgentCommandShimNames
        )
        return installAgentCommandShimsIfPossible(
            wrapperDirectoryURL: wrapperDirectoryURL,
            surfaceId: surfaceId,
            rootDirectory: rootDirectory,
            enabledCommands: enabledCommands,
            hermesProfileAliases: aliases,
            computerUseSettingFileURL: computerUseSettingFileURL,
            fileManager: fileManager
        )
    }

    private static var reservedAgentCommandShimNames: Set<String> {
        Set(TerminalSurfaceAgentCommandShimDefinition.bundled.map(\.commandName))
    }

    private static func installAgentCommandShimsIfPossible(
        wrapperDirectoryURL: URL,
        surfaceId: UUID,
        rootDirectory: URL,
        enabledCommands: Set<TerminalSurfaceAgentCommand>,
        hermesProfileAliases: [HermesProfileAliasResolver.Alias],
        computerUseSettingFileURL: URL? = nil,
        fileManager: FileManager
    ) -> TerminalSurfaceAgentCommandShimSet? {
        var availableDefinitions: [(
            definition: TerminalSurfaceAgentCommandShimDefinition,
            wrapperURL: URL
        )] = []
        for definition in TerminalSurfaceAgentCommandShimDefinition.bundled {
            guard enabledCommands.contains(definition.command) else { continue }
            let wrapperURL = wrapperDirectoryURL
                .appendingPathComponent(definition.wrapperName, isDirectory: false)
                .standardizedFileURL
            guard fileManager.isExecutableFile(atPath: wrapperURL.path) else { continue }
            availableDefinitions.append((definition, wrapperURL))
        }
        guard !availableDefinitions.isEmpty else { return nil }

        let shimParentDirectory = rootDirectory
            .appendingPathComponent("wmux-cli-shims", isDirectory: true)
            .standardizedFileURL
        let shimDirectory = shimParentDirectory
            .appendingPathComponent(surfaceId.uuidString, isDirectory: true)
            .standardizedFileURL
        let stagingDirectory = shimParentDirectory
            .appendingPathComponent(".\(surfaceId.uuidString).staging.\(UUID().uuidString)", isDirectory: true)
            .standardizedFileURL
        defer {
            try? fileManager.removeItem(at: stagingDirectory)
        }
        // A shared temporary directory lets another user create these
        // directories first or plant a symlink, so each one must be a real
        // directory this user owns before anything is written into it.
        let privateDirectoryCheck = PrivateDirectoryCheck()
        do {
            try fileManager.createDirectory(at: shimParentDirectory, withIntermediateDirectories: true)
            guard privateDirectoryCheck.makePrivate(atPath: shimParentDirectory.path) else { return nil }
            try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: false)
            guard privateDirectoryCheck.makePrivate(atPath: stagingDirectory.path) else { return nil }
        } catch {
            return nil
        }

        let computerUseSettingURL = computerUseSettingFileURL ?? computerUseLiveSettingFileURL(
            homeDirectory: fileManager.homeDirectoryForCurrentUser
        )
        var shims: [TerminalSurfaceAgentCommandShim] = []
        if let hermesDefinition = availableDefinitions.first(where: {
            $0.definition.commandName == "hermes"
        }) {
            for alias in hermesProfileAliases {
                guard let shim = installAgentCommandShim(
                    definition: hermesDefinition.definition,
                    commandName: alias.commandName,
                    hermesProfileAliasURL: URL(
                        fileURLWithPath: alias.wrapperPath,
                        isDirectory: false
                    ),
                    wrapperURL: hermesDefinition.wrapperURL,
                    stagingDirectory: stagingDirectory,
                    publishedDirectory: shimDirectory,
                    computerUseSettingFileURL: computerUseSettingURL,
                    fileManager: fileManager
                ) else { continue }
                shims.append(shim)
            }
        }
        for (definition, wrapperURL) in availableDefinitions {
            guard let shim = installAgentCommandShim(
                definition: definition,
                wrapperURL: wrapperURL,
                stagingDirectory: stagingDirectory,
                publishedDirectory: shimDirectory,
                computerUseSettingFileURL: computerUseSettingURL,
                fileManager: fileManager
            ) else { continue }
            shims.append(shim)
        }
        guard !shims.isEmpty else { return nil }
        do {
            if fileManager.fileExists(atPath: shimDirectory.path) {
                guard privateDirectoryCheck.makePrivate(atPath: shimDirectory.path) else { return nil }
                _ = try fileManager.replaceItemAt(
                    shimDirectory,
                    withItemAt: stagingDirectory,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try fileManager.moveItem(at: stagingDirectory, to: shimDirectory)
            }
        } catch {
            return nil
        }
        guard privateDirectoryCheck.makePrivate(atPath: shimDirectory.path) else { return nil }
        return TerminalSurfaceAgentCommandShimSet(
            directoryPath: shimDirectory.path,
            shims: shims
        )
    }

    private static func installAgentCommandShim(
        definition: TerminalSurfaceAgentCommandShimDefinition,
        commandName: String? = nil,
        hermesProfileAliasURL: URL? = nil,
        wrapperURL: URL,
        stagingDirectory: URL,
        publishedDirectory: URL,
        computerUseSettingFileURL: URL,
        fileManager: FileManager
    ) -> TerminalSurfaceAgentCommandShim? {
        let commandName = commandName ?? definition.commandName
        let stagingShimURL = stagingDirectory.appendingPathComponent(commandName, isDirectory: false)
        let publishedShimURL = publishedDirectory.appendingPathComponent(commandName, isDirectory: false)
        let wrapperInvocation: String
        if let hermesProfileAliasURL {
            // Hermes owns and can retarget this two-line wrapper while the
            // terminal remains open. Revalidate its bounded canonical form on
            // every invocation instead of freezing a profile into the shim.
            wrapperInvocation = """
            wmux_alias_path=\(shellSingleQuoted(hermesProfileAliasURL.path))
            wmux_alias_contents=""
            if [[ -f "$wmux_alias_path" && -x "$wmux_alias_path" ]]; then
                IFS= read -r -d '' -n 2049 wmux_alias_contents < "$wmux_alias_path" || true
                if (( ${#wmux_alias_contents} <= 2048 )); then
                    wmux_alias_contents="${wmux_alias_contents//$'\\r\\n'/$'\\n'}"
                    if [[ "$wmux_alias_contents" == *$'\\n' ]]; then
                        wmux_alias_contents="${wmux_alias_contents%$'\\n'}"
                    fi
                    if [[ "$wmux_alias_contents" == *$'\\n'* ]]; then
                        wmux_alias_header="${wmux_alias_contents%%$'\\n'*}"
                        wmux_alias_line="${wmux_alias_contents#*$'\\n'}"
                        wmux_alias_argument_suffix=' "$@"'
                        if [[ "$wmux_alias_header" == '#!/bin/sh' &&
                              "$wmux_alias_line" != *$'\\n'* &&
                              "$wmux_alias_line" == exec\\ *"$wmux_alias_argument_suffix" ]]; then
                            wmux_alias_command="${wmux_alias_line#exec }"
                            wmux_alias_command="${wmux_alias_command%"$wmux_alias_argument_suffix"}"
                            if [[ "$wmux_alias_command" == *" -p "* ]]; then
                                wmux_alias_profile="${wmux_alias_command##* -p }"
                                wmux_alias_executable="${wmux_alias_command% -p *}"
                                wmux_alias_resolved_executable="$wmux_alias_executable"
                                if [[ "${wmux_alias_executable:0:1}" == "'" &&
                                      "${wmux_alias_executable: -1}" == "'" ]]; then
                                    wmux_alias_resolved_executable="${wmux_alias_executable:1:${#wmux_alias_executable}-2}"
                                elif [[ "$wmux_alias_executable" == *[[:space:]]* ]]; then
                                    wmux_alias_resolved_executable=""
                                fi
                                if [[ "$wmux_alias_profile" =~ ^[a-z0-9][a-z0-9_-]{0,63}$ &&
                                      "${wmux_alias_resolved_executable##*/}" == "hermes" ]]; then
                                    exec "$wmux_wrapper" -p "$wmux_alias_profile" "$@"
                                fi
                            fi
                        fi
                    fi
                fi
            fi
            """
        } else {
            wrapperInvocation = "exec \"$wmux_wrapper\" \"$@\""
        }
        let script = """
        #!/bin/bash
        wmux_wrapper=\(shellSingleQuoted(wrapperURL.path))
        wmux_shim_root=\(shellSingleQuoted(publishedDirectory.path))
        wmux_computer_use_setting=\(shellSingleQuoted(computerUseSettingFileURL.path))
        wmux_computer_use_enabled="${WMUX_COMPUTER_USE_APP_ENABLED:-1}"
        if [[ -r "$wmux_computer_use_setting" ]]; then
            IFS= read -r wmux_computer_use_enabled < "$wmux_computer_use_setting" || true
        fi
        # A functional `$cmux-cua` request is the explicit opt-in. Keep the
        # live setting available to the app for first-use reconciliation, but
        # do not turn an ordinary settings-off value into the hard kill switch.
        # Only WMUX_COMPUTER_USE_MCP_DISABLED=1 (or managed policy in cmux)
        # blocks attachment.
        if [[ ! -x "$wmux_wrapper" && -n "${WMUX_BUNDLED_CLI_PATH:-}" ]]; then
            wmux_candidate="$(dirname "$WMUX_BUNDLED_CLI_PATH")/\(definition.wrapperName)"
            if [[ -x "$wmux_candidate" ]]; then
                wmux_wrapper="$wmux_candidate"
            fi
        fi
        if [[ ! -x "$wmux_wrapper" ]]; then
            wmux_cli="$(command -v cmux 2>/dev/null || true)"
            if [[ -n "$wmux_cli" ]]; then
                wmux_candidate="$(dirname "$wmux_cli")/\(definition.wrapperName)"
                if [[ -x "$wmux_candidate" ]]; then
                    wmux_wrapper="$wmux_candidate"
                fi
            fi
        fi
        export \(definition.environmentVariablePrefix)_WRAPPER_SHIM=\(shellSingleQuoted(publishedShimURL.path))
        export \(definition.environmentVariablePrefix)_WRAPPER_SHIM_ROOT="$wmux_shim_root"
        if [[ -x "$wmux_wrapper" ]]; then
            \(wrapperInvocation)
        fi
        wmux_path_without_shim=""
        wmux_old_ifs="$IFS"
        wmux_globbing_was_disabled=0
        case "$-" in
            *f*) wmux_globbing_was_disabled=1 ;;
            *) set -f ;;
        esac
        IFS=:
        for wmux_entry in ${PATH:-}; do
            if [[ "$wmux_entry" == "$wmux_shim_root" || "$wmux_entry" == */cmux-cli-shims/* || "$wmux_entry" == */cmux-cli-shims ]]; then
                continue
            fi
            if [[ -z "$wmux_path_without_shim" ]]; then
                wmux_path_without_shim="$wmux_entry"
            else
                wmux_path_without_shim="$wmux_path_without_shim:$wmux_entry"
            fi
        done
        IFS="$wmux_old_ifs"
        if [[ "$wmux_globbing_was_disabled" == 0 ]]; then
            set +f
        fi
        export PATH="$wmux_path_without_shim"
        exec \(shellSingleQuoted(commandName)) "$@"
        """

        do {
            try script.write(to: stagingShimURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: stagingShimURL.path)
            return TerminalSurfaceAgentCommandShim(
                commandName: commandName,
                wrapperName: definition.wrapperName,
                environmentVariablePrefix: definition.environmentVariablePrefix,
                directoryPath: publishedDirectory.path,
                executablePath: publishedShimURL.path
            )
        } catch {
            return nil
        }
    }
}
