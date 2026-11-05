/// Stores resolved hooks and their content-sensitive fingerprints for one cache key.
struct WmuxNotificationHookCacheEntry {
    let fingerprints: [WmuxNotificationHookFileFingerprint]
    let hooks: [WmuxResolvedNotificationHook]
    var lastAccessSequence: UInt64
}
