/// Associates a parsed notification-hook configuration with its content fingerprint.
struct WmuxNotificationHookParsedConfig {
    let fingerprint: WmuxNotificationHookFileFingerprint
    let config: WmuxConfigFile?
}
