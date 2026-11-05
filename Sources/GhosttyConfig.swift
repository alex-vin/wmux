import WmuxTerminalCore

/// App-target alias for ``WmuxTerminalCore/GhosttyConfig``, lifted into
/// WmuxTerminalCore in stack D tranche A. Keeps every `GhosttyConfig` call site
/// (and `GhosttyConfig.ColorSchemePreference` / `GhosttyConfig.UserAppearanceConfigSummary`
/// member lookups) byte-identical across the app target.
typealias GhosttyConfig = WmuxTerminalCore.GhosttyConfig
