import XCTest

extension XCUIApplication {
    static func cmuxTestApplication() -> XCUIApplication {
        let application = XCUIApplication()
        application.launchEnvironment["WMUX_UI_TEST_PROCESS"] = "1"
        return application
    }
}
