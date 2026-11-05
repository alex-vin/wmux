import Foundation

extension WMUXCLI {
    static var sshCommandUsage: String {
        let help = String(localized: "cli.help.ssh", defaultValue: """
        Usage: wmux ssh <destination> [flags] [-- <remote-command-args>]

        Create a new workspace, mark it as remote-SSH, and start an SSH session in that workspace.
        wmux will also establish a local SSH proxy endpoint so browser traffic can egress from the remote host.

        Flags:
          --name <title>          Optional workspace title
          --port <n>              SSH port
          --identity <path>       SSH identity file path
          -A, --forward-agent     Forward the caller's SSH agent; also honors ForwardAgent yes from ssh_config
          -a, --no-forward-agent  Disable SSH agent forwarding for this workspace
          --ssh-option <opt>      Extra SSH -o option (repeatable)
          --window <id|ref|index> Target window for the managed workspace
          --no-focus              Create workspace without switching to it

        Example:
          wmux ssh dev@my-host
          wmux ssh dev@my-host --name "gpu-box" --port 2222 --identity ~/.ssh/id_ed25519
          wmux ssh dev@my-host --forward-agent
          wmux ssh dev@my-host --ssh-option UserKnownHostsFile=/dev/null --ssh-option StrictHostKeyChecking=no
        """)
        let moshHelp = String(
            localized: "cli.help.ssh.mosh",
            defaultValue: """
            Mosh terminal transport:
              --transport <ssh|mosh>  Interactive terminal transport (default: ssh)

            SSH continues to handle remote features; Mosh carries only the interactive
            terminal. If Mosh is missing locally or remotely, wmux reports it and uses SSH.

            Example:
              wmux ssh dev@my-host --transport mosh
            """
        )
        let initialCommandHelp = String(
            localized: "cli.help.ssh.initialCommand",
            defaultValue: """
            Initial command:
              --command <text>        Run text once in the initial remote terminal after shell startup

            Example:
              wmux ssh dev@my-host --command 'omp "investigate auth"'
            """
        )
        return "\(help)\n\n\(initialCommandHelp)\n\n\(moshHelp)\n\n\(openFocusFlagsHelp)"
    }

    static var moshCommandUsage: String {
        String(localized: "cli.help.mosh", defaultValue: """
        Usage: wmux mosh <destination> [flags] [-- <remote-command-args>]

        Create a first-class remote workspace with Mosh as the interactive terminal
        transport. SSH remains the management lane for remote metadata, daemon control,
        proxy/egress, uploads, cwd/git integration, and reconnect actions.

        Accepts the same workspace and SSH bootstrap flags as `wmux ssh`. If Mosh is
        unavailable locally or remotely, wmux explains why and falls back to SSH.

        Example:
          wmux mosh dev@my-host
        """)
    }

    static var moshTmuxCommandUsage: String {
        String(localized: "cli.help.mosh-tmux", defaultValue: """
        Usage: wmux mosh-tmux <destination> [--session <name>] [flags]

        Create a first-class remote workspace whose Mosh terminal creates or attaches
        to a named tmux session (default: main). The tmux profile persists across wmux
        workspace reconnect and app session restore.

        This is a terminal-attached tmux session that roams with Mosh. It is distinct
        from `wmux ssh-tmux`, which uses SSH and tmux control mode to mirror sessions,
        windows, and panes as native wmux workspaces, tabs, and splits.

        `--session <name>` selects the tmux session. All other workspace and SSH
        bootstrap flags match `wmux mosh`. If Mosh is unavailable, wmux runs the
        same managed tmux profile over SSH.

        Example:
          wmux mosh-tmux dev@my-host
          wmux mosh-tmux dev@my-host --session agent-main
        """)
    }
}
