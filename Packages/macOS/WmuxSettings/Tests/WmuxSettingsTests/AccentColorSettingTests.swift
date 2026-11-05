import WmuxFoundation
import Foundation
import Testing
@testable import WmuxSettings

struct AccentColorSettingTests {
    @Test func catalogKeyStoresTheModeTheResolverReads() throws {
        let suite = "AccentColorSettingTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = AppCatalogSection().accentColor

        #expect(key.id == "app.accentColor")
        #expect(key.userDefaultsKey == WmuxAccentColorMode.userDefaultsKey)
        #expect(key.defaultValue == .cmux)

        let client = UserDefaultsSettingsClient(defaults: defaults)
        for mode in WmuxAccentColorMode.allCases {
            client.set(mode, for: key)
            #expect(WmuxAccentColorMode.stored(in: defaults) == mode)
            #expect(client.value(for: key) == mode)
        }
    }
}
