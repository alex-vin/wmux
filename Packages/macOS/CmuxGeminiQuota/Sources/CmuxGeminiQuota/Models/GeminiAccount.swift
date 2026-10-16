public import Foundation

/// Represents a Google account and its associated Gemini authentication tokens and quota.
public struct GeminiAccount: Sendable, Codable, Identifiable, Equatable {
    /// Unique identifier for the account, typically the email address.
    public let id: String
    /// The Google account email address.
    public var email: String
    /// User profile display name, if available.
    public var name: String?
    /// OAuth access token.
    public var accessToken: String?
    /// OAuth refresh token.
    public var refreshToken: String?
    /// OpenID Connect ID token JWT.
    public var idToken: String?
    /// Expiration timestamp in epoch seconds.
    public var expiryTimestamp: TimeInterval
    /// Latest quota snapshot.
    public var quota: GeminiQuotaSnapshot
    /// Whether the account has been disabled (e.g. invalid_grant).
    public var isDisabled: Bool
    /// Explanation if disabled.
    public var disabledReason: String?

    /// Local-part of the email (before the `@` sign).
    public var emailLocalPart: String {
        let parts = email.split(separator: "@")
        return parts.first.map(String.init) ?? email
    }

    /// Whether the access token is expiring soon (less than 15 minutes / 900 seconds remaining).
    public func needsTokenRefresh(now: Date = Date()) -> Bool {
        expiryTimestamp - now.timeIntervalSince1970 < 900.0
    }

    /// Creates an account instance.
    public init(
        id: String,
        email: String,
        name: String? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        idToken: String? = nil,
        expiryTimestamp: TimeInterval = 0,
        quota: GeminiQuotaSnapshot = GeminiQuotaSnapshot(),
        isDisabled: Bool = false,
        disabledReason: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.expiryTimestamp = expiryTimestamp
        self.quota = quota
        self.isDisabled = isDisabled
        self.disabledReason = disabledReason
    }

    /// Serializes the token payload into the format expected by the Antigravity `agy` CLI.
    ///
    /// - Returns: JSON string representing the token dictionary.
    public func agyPayloadJSON() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        let expiryString = formatter.string(from: Date(timeIntervalSince1970: expiryTimestamp))

        var tokenDict: [String: Any] = [
            "access_token": accessToken ?? "",
            "token_type": "Bearer",
            "refresh_token": refreshToken ?? "",
            "expiry": expiryString,
        ]

        var payload: [String: Any] = [
            "token": tokenDict,
            "auth_method": "consumer"
        ]
        if let idToken, !idToken.isEmpty {
            payload["id_token"] = idToken
        }

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    /// Formats the keyring value with the `go-keyring-base64:` prefix.
    public func agyKeyringSecretValue() -> String {
        let payload = agyPayloadJSON()
        let b64 = Data(payload.utf8).base64EncodedString()
        return "go-keyring-base64:\(b64)"
    }
}
