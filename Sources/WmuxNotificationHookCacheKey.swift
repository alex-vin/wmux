/// Identifies notification-hook resolution for one working directory and global configuration.
struct WmuxNotificationHookCacheKey: Hashable {
    let directory: String?
    let globalConfigPath: String
}
