import WMUXAuthCore
import Testing
@testable import WmuxAuthRuntime

@Suite struct AuthConfigTests {
    @Test func productionUsesStackWhitelistedCmuxDomain() {
        let config = AuthConfig(environment: .production)

        #expect(config.magicLinkCallbackURL == "https://cmux.com/auth/callback")
        #expect(config.apiBaseURL == "https://cmux.com")
    }
}
