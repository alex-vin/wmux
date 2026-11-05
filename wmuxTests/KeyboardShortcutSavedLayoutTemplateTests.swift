import XCTest
import WmuxSettings
@testable import WmuxSettingsUI

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

private typealias ShortcutStroke = WmuxSettings.ShortcutStroke

final class KeyboardShortcutSavedLayoutTemplateTests: XCTestCase {
    func testSaveLayoutTemplateSettingsPackageActionStaysAligned() {
        guard let settingsAction = ShortcutAction(
            rawValue: KeyboardShortcutSettings.Action.saveLayoutTemplate.rawValue
        ) else {
            XCTFail("Expected WmuxSettings.ShortcutAction for saveLayoutTemplate")
            return
        }
        XCTAssertEqual(settingsAction.defaultStroke, ShortcutStroke(key: "s", command: true, control: true))
        XCTAssertEqual(settingsAction.displayName, KeyboardShortcutSettings.Action.saveLayoutTemplate.label)
    }
}
