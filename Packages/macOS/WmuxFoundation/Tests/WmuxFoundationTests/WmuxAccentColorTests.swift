import AppKit
import Foundation
import Testing

@testable import WmuxFoundation

@Suite struct WmuxAccentColorTests {
    @Test func cmuxModeUsesTheCmuxBlues() {
        let accent = WmuxAccentColor(mode: .cmux)
        #expect(rgbBytes(accent.nsColor(isDark: false)) == [0, 136, 255])
        #expect(rgbBytes(accent.nsColor(isDark: true)) == [0, 145, 255])
    }

    @Test func systemModeUsesTheResolvedControlAccent() throws {
        let accent = WmuxAccentColor(mode: .system)
        for isDark in [false, true] {
            let appearance = try #require(NSAppearance(named: isDark ? .darkAqua : .aqua))
            var expected: [Int] = []
            appearance.performAsCurrentDrawingAppearance {
                expected = rgbBytes(NSColor.controlAccentColor)
            }
            #expect(!expected.isEmpty)
            #expect(rgbBytes(accent.nsColor(isDark: isDark)) == expected)
        }
    }

    @Test func storedModeParsesAndFallsBackToCmux() throws {
        let suite = "WmuxAccentColorTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(WmuxAccentColorMode.stored(in: defaults) == .cmux)
        for mode in WmuxAccentColorMode.allCases {
            defaults.set(mode.rawValue, forKey: WmuxAccentColorMode.userDefaultsKey)
            #expect(WmuxAccentColorMode.stored(in: defaults) == mode)
        }
        defaults.set("purple", forKey: WmuxAccentColorMode.userDefaultsKey)
        #expect(WmuxAccentColorMode.stored(in: defaults) == .cmux)
    }

    @Test func customModeDrawsTheStoredColorInBothSchemes() throws {
        let suite = "WmuxAccentColorTests.custom.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(WmuxAccentColorMode.custom.rawValue, forKey: WmuxAccentColorMode.userDefaultsKey)
        defaults.set(" ff6a00 ", forKey: WmuxAccentColorMode.customHexUserDefaultsKey)
        let accent = WmuxAccentColor.stored(in: defaults)
        #expect(accent.mode == .custom)
        #expect(accent.customHex == "#FF6A00")
        #expect(rgbBytes(accent.nsColor(isDark: false)) == [255, 106, 0])
        #expect(rgbBytes(accent.nsColor(isDark: true)) == [255, 106, 0])
    }

    @Test func customModeWithoutAValidColorFallsBackToCmuxBlue() {
        for hex in [nil, "", "not-a-color", "#FF6A00AA"] {
            let accent = WmuxAccentColor(mode: .custom, customHex: hex)
            #expect(accent.customHex == nil)
            #expect(rgbBytes(accent.nsColor(isDark: false)) == [0, 136, 255])
            #expect(rgbBytes(accent.nsColor(isDark: true)) == [0, 145, 255])
        }
    }

    @MainActor
    @Test func observerPostsWhenTheCustomColorChanges() throws {
        let suite = "WmuxAccentColorTests.customObserver.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(WmuxAccentColorMode.custom.rawValue, forKey: WmuxAccentColorMode.userDefaultsKey)
        defaults.set("#FF6A00", forKey: WmuxAccentColorMode.customHexUserDefaultsKey)

        let observer = WmuxAccentColorObserver(defaults: defaults, center: NotificationCenter())
        #expect(observer.current.customHex == "#FF6A00")
        defaults.set("#00FF00", forKey: WmuxAccentColorMode.customHexUserDefaultsKey)
        #expect(observer.refresh() == true)
        #expect(rgbBytes(observer.current.nsColor(isDark: true)) == [0, 255, 0])
        #expect(observer.refresh() == false)
    }

    @Test func settingsFileValueRoundTripsEveryMode() throws {
        #expect(WmuxAccentColorMode.settingsFileValue(mode: .cmux, customHex: "#FF6A00") == "wmux")
        #expect(WmuxAccentColorMode.settingsFileValue(mode: .system, customHex: nil) == "system")
        #expect(WmuxAccentColorMode.settingsFileValue(mode: .custom, customHex: "ff6a00") == "#FF6A00")
        #expect(WmuxAccentColorMode.settingsFileValue(mode: .custom, customHex: nil) == nil)

        for (mode, hex) in [(WmuxAccentColorMode.cmux, nil), (.system, nil), (.custom, "#FF6A00")] as [(WmuxAccentColorMode, String?)] {
            let value = try #require(WmuxAccentColorMode.settingsFileValue(mode: mode, customHex: hex))
            let parsed = try #require(WmuxAccentColorMode.parseSettingsFileValue(value))
            #expect(parsed.mode == mode)
            #expect(parsed.customHex == hex)
        }
        for invalid in ["custom", "purple", "#FF6A", "#FF6A00AA", ""] {
            #expect(WmuxAccentColorMode.parseSettingsFileValue(invalid) == nil)
        }
    }

    @Test func appearanceResolvesToMatchingScheme() throws {
        let dark = try #require(NSAppearance(named: .darkAqua))
        let aqua = try #require(NSAppearance(named: .aqua))
        for accent in WmuxAccentColorMode.allCases.map(WmuxAccentColor.init(mode:)) {
            #expect(rgbBytes(accent.nsColor(for: dark)) == rgbBytes(accent.nsColor(isDark: true)))
            #expect(rgbBytes(accent.nsColor(for: aqua)) == rgbBytes(accent.nsColor(isDark: false)))
            #expect(rgbBytes(accent.nsColor(for: nil)) == rgbBytes(accent.nsColor(isDark: false)))
        }
    }

    @Test func dynamicColorFollowsDrawingAppearance() throws {
        let dark = try #require(NSAppearance(named: .darkAqua))
        let aqua = try #require(NSAppearance(named: .aqua))
        let accent = WmuxAccentColor(mode: .cmux)
        var darkBytes: [Int] = []
        var lightBytes: [Int] = []
        dark.performAsCurrentDrawingAppearance {
            darkBytes = rgbBytes(accent.dynamicNSColor)
        }
        aqua.performAsCurrentDrawingAppearance {
            lightBytes = rgbBytes(accent.dynamicNSColor)
        }
        #expect(darkBytes == [0, 145, 255])
        #expect(lightBytes == [0, 136, 255])
    }

    @Test func builtInAgentStatusBlueResolvesToTheAccent() {
        for accent in WmuxAccentColorMode.allCases.map(WmuxAccentColor.init(mode:)) {
            for hex in ["#4C8DFF", "#4c8dff", " #4C8DFF "] {
                let color = accent.statusEntryColor(hex: hex, isDark: true)
                #expect(color.map(rgbBytes) == rgbBytes(accent.nsColor(isDark: true)))
            }
        }
    }

    @Test func otherStatusColorsStayAsWritten() {
        let accent = WmuxAccentColor(mode: .system)
        #expect(accent.statusEntryColor(hex: "#00FF00", isDark: false).map(rgbBytes) == [0, 255, 0])
        #expect(accent.statusEntryColor(hex: nil, isDark: false) == nil)
        #expect(accent.statusEntryColor(hex: "not-a-color", isDark: false) == nil)
    }

    @MainActor
    @Test func observerResolvesOnceAndPostsOnlyOnChange() throws {
        let suite = "WmuxAccentColorTests.observer.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let center = NotificationCenter()
        var posts = 0
        let token = center.addObserver(forName: WmuxAccentColor.didChangeNotification, object: nil, queue: nil) { _ in
            posts += 1
        }
        defer { center.removeObserver(token) }

        let observer = WmuxAccentColorObserver(defaults: defaults, center: center)
        #expect(observer.current.mode == .cmux)
        #expect(observer.refresh() == false)

        defaults.set(WmuxAccentColorMode.system.rawValue, forKey: WmuxAccentColorMode.userDefaultsKey)
        #expect(observer.current.mode == .cmux)
        #expect(observer.refresh() == true)
        #expect(observer.current.mode == .system)
        #expect(observer.refresh() == false)

        defaults.set(WmuxAccentColorMode.cmux.rawValue, forKey: WmuxAccentColorMode.userDefaultsKey)
        #expect(observer.refresh() == true)
        #expect(posts == 2)
    }

    private func rgbBytes(_ color: NSColor) -> [Int] {
        guard let srgb = color.usingColorSpace(.sRGB) else { return [] }
        return [srgb.redComponent, srgb.greenComponent, srgb.blueComponent]
            .map { Int(($0 * 255).rounded()) }
    }
}
