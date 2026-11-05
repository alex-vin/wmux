import WmuxSettings

struct SurfaceTabBarButtonConfiguration {
    let buttons: [WmuxSurfaceTabBarButton]
    let sourcePath: String?
    let globalConfigPath: String
    let settingPresets: [String: WmuxSettingValue]
    let terminalCommandSourcePaths: [String: String]
    let workspaceCommands: [String: WmuxResolvedCommand]
}
