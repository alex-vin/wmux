import Bonsplit
import Foundation

enum WmuxSurfaceTabBarBuiltInAction: String, Codable, Sendable, CaseIterable, Hashable {
    case newWorkspace = "wmux.newWorkspace"
    case newAgentChat = "wmux.newAgentChat"
    case cloudVM = "wmux.cloudvm"
    case newCloudWorkspace = "wmux.newCloudWorkspace"
    case newCloudMachine = "wmux.newCloudMachine"
    case mobileConnect = "wmux.mobileconnect"
    case newTerminal = "wmux.newTerminal"
    case newBrowser = "wmux.newBrowser"
    case newSimulator = "wmux.newSimulator"
    case splitRight = "wmux.splitRight"
    case splitDown = "wmux.splitDown"
    case copyWorkingDirectory = "wmux.copyWorkingDirectory"
    case copyProjectRoot = "wmux.copyProjectRoot"
    case copyScreen = "wmux.copyScreen"

    init?(configID: String) {
        switch configID {
        case "wmux.newWorkspace", "newWorkspace":
            self = .newWorkspace
        case "wmux.newAgentChat", "wmux.agentChat", "newAgentChat", "new-agent-chat", "agentChat":
            self = .newAgentChat
        case "wmux.cloudvm", "wmux.cloudVM", "cloudVM", "cloudvm",
             "wmux.newCloudVM", "wmux.newCloudVm", "newCloudVM", "newCloudVm",
             "wmux.startCloudVM", "wmux.startCloudVm", "startCloudVM", "startCloudVm":
            self = .cloudVM
        case "wmux.newCloudWorkspace", "newCloudWorkspace":
            self = .newCloudWorkspace
        case "wmux.newCloudMachine", "newCloudMachine":
            self = .newCloudMachine
        case "wmux.mobileconnect", "wmux.mobileConnect", "mobileConnect", "mobileconnect",
             "wmux.connectPhone", "connectPhone":
            self = .mobileConnect
        case "wmux.newTerminal", "newTerminal":
            self = .newTerminal
        case "wmux.newBrowser", "newBrowser":
            self = .newBrowser
        case "wmux.newSimulator", "newSimulator", "new-simulator", "simulator":
            self = .newSimulator
        case "wmux.splitRight", "splitRight":
            self = .splitRight
        case "wmux.splitDown", "splitDown":
            self = .splitDown
        case "wmux.copyWorkingDirectory", "copyWorkingDirectory":
            self = .copyWorkingDirectory
        case "wmux.copyProjectRoot", "copyProjectRoot":
            self = .copyProjectRoot
        case "wmux.copyScreen", "copyScreen":
            self = .copyScreen
        default:
            return nil
        }
    }

    var configID: String {
        rawValue
    }

    var resolvedConfigMetadata: (title: String, keywords: [String]) {
        switch self {
        case .newWorkspace:
            return (String(localized: "command.newWorkspace.title", defaultValue: "New Workspace"), ["create", "new", "workspace"])
        case .newAgentChat:
            return (String(localized: "command.newAgentChat.title", defaultValue: "New agent chat"), ["create", "new", "agent", "chat", "browser", "codex", "claude"])
        case .cloudVM:
            return (String(localized: "command.cloudVM.title", defaultValue: "Open Base"), ["base", "cloud", "vm", "virtual", "machine", "remote"])
        case .newCloudWorkspace:
            return (String(localized: "command.newCloudWorkspace.title", defaultValue: "New Cloud Workspace"), ["new", "create", "cloud", "vm", "machine", "workspace", "remote"])
        case .newCloudMachine:
            return (String(localized: "command.newCloudMachine.title", defaultValue: "New Cloud Machine"), ["new", "create", "cloud", "vm", "machine", "workspace", "remote"])
        case .mobileConnect:
            return (
                String(localized: "command.mobileConnect.title", defaultValue: "Open Mobile Pairing"),
                ["tailscale", "iroh", "iphone", "ipad", "mobile", "phone", "pair", "connect", "qr"]
            )
        case .newTerminal:
            return (String(localized: "command.newTerminalTab.title", defaultValue: "New Terminal Tab"), ["new", "terminal", "tab", "surface"])
        case .newBrowser:
            return (String(localized: "command.newBrowserTab.title", defaultValue: "New Browser Tab"), ["new", "browser", "tab", "surface"])
        case .newSimulator:
            return (String(localized: "command.newSimulatorPane.title", defaultValue: "New Simulator Pane"), ["new", "simulator", "iphone", "ipad", "ios", "surface"])
        case .splitRight:
            return (String(localized: "command.terminalSplitRight.title", defaultValue: "Split Right"), ["terminal", "split", "right"])
        case .splitDown:
            return (String(localized: "command.terminalSplitDown.title", defaultValue: "Split Down"), ["terminal", "split", "down"])
        case .copyWorkingDirectory:
            return (String(localized: "command.copyWorkingDirectory.title", defaultValue: "Copy Working Directory"), ["copy", "clipboard", "path", "directory", "cwd", "pwd"])
        case .copyProjectRoot:
            return (String(localized: "command.copyProjectRoot.title", defaultValue: "Copy Project Root"), ["copy", "clipboard", "project", "git", "root", "repository", "path"])
        case .copyScreen:
            return (String(localized: "command.copyScreen.title", defaultValue: "Copy Visible Screen"), ["copy", "clipboard", "screen", "output", "terminal", "visible"])
        }
    }

    var defaultIcon: String {
        switch self {
        case .newWorkspace:
            return "plus.square"
        case .newAgentChat:
            return "message"
        case .cloudVM:
            return "cloud"
        case .newCloudWorkspace:
            return "cloud.fill"
        case .newCloudMachine:
            return "cloud"
        case .mobileConnect:
            return "iphone"
        case .newTerminal:
            return "terminal"
        case .newBrowser:
            return "globe"
        case .newSimulator:
            return "iphone.gen3"
        case .splitRight:
            return "square.split.2x1"
        case .splitDown:
            return "square.split.1x2"
        case .copyWorkingDirectory:
            return "doc.on.doc"
        case .copyProjectRoot:
            return "arrow.triangle.branch"
        case .copyScreen:
            return "text.viewfinder"
        }
    }

    var bonsplitAction: BonsplitConfiguration.SplitActionButton.Action? {
        switch self {
        case .newWorkspace, .newAgentChat, .cloudVM, .newCloudWorkspace, .newCloudMachine, .mobileConnect, .newSimulator,
             .copyWorkingDirectory, .copyProjectRoot, .copyScreen:
            return nil
        case .newTerminal:
            return .newTerminal
        case .newBrowser:
            return .newBrowser
        case .splitRight:
            return .splitRight
        case .splitDown:
            return .splitDown
        }
    }
}

extension WmuxSurfaceTabBarBuiltInAction {
    /// The user-editable shortcut that triggers the same behavior as this
    /// built-in action. Menus that list built-in actions read the live
    /// `KeyboardShortcutSettings` value through this mapping, so a rebind or
    /// an unbind in Settings or `cmux.json` shows up the next time the menu
    /// opens. Actions with no cmux-owned shortcut return nil.
    var shortcutAction: KeyboardShortcutSettings.Action? {
        switch self {
        case .newWorkspace: return .newTab
        case .newCloudWorkspace: return .newCloudWorkspace
        case .newCloudMachine: return .newCloudMachine
        case .newTerminal: return .newSurface
        case .newBrowser: return .openBrowser
        case .splitRight: return .splitRight
        case .splitDown: return .splitDown
        case .newAgentChat, .cloudVM, .mobileConnect, .newSimulator,
             .copyWorkingDirectory, .copyProjectRoot, .copyScreen: return nil
        }
    }

    @MainActor
    var isAvailable: Bool {
        Workspace.surfaceTabBarBuiltInActionIsAvailable(self)
    }
}

@MainActor
func surfaceTabBarBuiltInActionIsAvailable(_ action: WmuxSurfaceTabBarBuiltInAction) -> Bool {
    Workspace.surfaceTabBarBuiltInActionIsAvailable(action)
}
