import Foundation

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@MainActor
extension KeyboardShortcutSettings {
    static func installIsolatedTestFileStore(prefix: String) -> KeyboardShortcutSettingsFileStore {
        let original = settingsFileStore
        let settingsFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString).json", isDirectory: false)
        settingsFileStore = KeyboardShortcutSettingsFileStore(
            primaryPath: settingsFileURL.path,
            fallbackPath: nil,
            additionalFallbackPaths: [],
            startWatching: false
        )
        return original
    }
}
