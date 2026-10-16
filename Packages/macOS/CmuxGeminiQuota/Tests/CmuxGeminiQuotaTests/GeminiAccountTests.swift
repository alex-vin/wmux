import Foundation
import Testing
@testable import CmuxGeminiQuota

@Suite("GeminiAccountTests")
struct GeminiAccountTests {
    @Test("Token serialization matches Antigravity format")
    func tokenSerializationMatchesAntigravityFormat() throws {
        let account = GeminiAccount(
            id: "alex@example.com",
            email: "alex@example.com",
            name: "Alex",
            accessToken: "mock_access",
            refreshToken: "mock_refresh",
            idToken: "mock_id_token",
            expiryTimestamp: 1800000000
        )

        let payload = account.agyPayloadJSON()
        #expect(payload.contains("mock_access"))
        #expect(payload.contains("mock_refresh"))
        #expect(payload.contains("consumer"))
        #expect(payload.contains("mock_id_token"))

        let secret = account.agyKeyringSecretValue()
        #expect(secret.hasPrefix("go-keyring-base64:"))

        let b64Part = String(secret.dropFirst("go-keyring-base64:".count))
        let decodedData = try #require(Data(base64Encoded: b64Part))
        let decodedString = try #require(String(data: decodedData, encoding: .utf8))
        #expect(decodedString == payload)
    }

    @Test("Token expiration calculation is accurate")
    func tokenExpirationCalculation() {
        let now = Date()
        let freshAccount = GeminiAccount(
            id: "fresh@example.com",
            email: "fresh@example.com",
            expiryTimestamp: now.timeIntervalSince1970 + 3600
        )
        #expect(!freshAccount.needsTokenRefresh(now: now))

        let expiringAccount = GeminiAccount(
            id: "expiring@example.com",
            email: "expiring@example.com",
            expiryTimestamp: now.timeIntervalSince1970 + 300 // 5 mins remaining
        )
        #expect(expiringAccount.needsTokenRefresh(now: now))
    }

    @Test("Subscription tier normalization")
    func subscriptionTierNormalization() {
        #expect(GeminiSubscriptionTier.normalize("pro-tier") == .pro)
        #expect(GeminiSubscriptionTier.normalize("Google One Premium") == .pro)
        #expect(GeminiSubscriptionTier.normalize("helium-tier") == .ultra)
        #expect(GeminiSubscriptionTier.normalize("starter-tier") == .free)
        #expect(GeminiSubscriptionTier.normalize(nil) == .free)
    }

    @Test("OAuth token response decodes integer and floating-point expires_in")
    func oAuthTokenResponseDecoding() throws {
        let jsonInt = """
        {
            "access_token": "ya29.test1234",
            "token_type": "Bearer",
            "expires_in": 3599,
            "refresh_token": "1//test_refresh",
            "id_token": "eyJhbGciOi..."
        }
        """.data(using: .utf8)!

        let decodedInt = try JSONDecoder().decode(GeminiOAuthTokenResponse.self, from: jsonInt)
        #expect(decodedInt.accessToken == "ya29.test1234")
        #expect(decodedInt.expiresIn == 3599.0)
        #expect(decodedInt.refreshToken == "1//test_refresh")
        #expect(decodedInt.idToken == "eyJhbGciOi...")

        let jsonDouble = """
        {
            "access_token": "ya29.test5678",
            "expires_in": 3600.5
        }
        """.data(using: .utf8)!

        let decodedDouble = try JSONDecoder().decode(GeminiOAuthTokenResponse.self, from: jsonDouble)
        #expect(decodedDouble.accessToken == "ya29.test5678")
        #expect(decodedDouble.expiresIn == 3600.5)
        #expect(decodedDouble.refreshToken == nil)
        #expect(decodedDouble.idToken == nil)
    }
}
