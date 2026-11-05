import Foundation

/// Couples a hook file's cache identity with the exact bytes represented by that identity.
struct WmuxNotificationHookFileSnapshot {
    let fingerprint: WmuxNotificationHookFileFingerprint
    let contents: Data?
}
