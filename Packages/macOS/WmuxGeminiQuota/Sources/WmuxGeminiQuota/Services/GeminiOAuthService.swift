public import Foundation

/// Token response returned by Google OAuth 2.0 endpoints.
public struct GeminiOAuthTokenResponse: Sendable, Codable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let expiresIn: Double?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        idToken: String? = nil,
        expiresIn: Double? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.expiresIn = expiresIn
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        self.idToken = try container.decodeIfPresent(String.self, forKey: .idToken)
        if let d = try? container.decodeIfPresent(Double.self, forKey: .expiresIn) {
            self.expiresIn = d
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .expiresIn) {
            self.expiresIn = Double(i)
        } else {
            self.expiresIn = nil
        }
    }
}

/// Handles Google OAuth 2.0 authorization, code exchange, token refresh, and user profile retrieval.
public actor GeminiOAuthService {
    public static let clientID = "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com"
    public static let clientSecret = "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"
    private static let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
    private static let userInfoURL = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
    private static let authBaseURL = "https://accounts.google.com/o/oauth2/v2/auth"

    private let session: URLSession

    /// Creates an OAuth service.
    ///
    /// - Parameter session: URLSession used for network requests.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Constructs the browser authorization URL.
    ///
    /// - Parameters:
    ///   - redirectURI: The local redirect URI (e.g. `http://127.0.0.1:port/oauth2callback`).
    ///   - state: Random state token to prevent CSRF.
    /// - Returns: Complete Google OAuth authorization URL.
    public nonisolated func authorizationURL(redirectURI: String, state: String) -> URL? {
        let scopes = [
            "openid",
            "https://www.googleapis.com/auth/cloud-platform",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile",
            "https://www.googleapis.com/auth/cclog",
            "https://www.googleapis.com/auth/experimentsandconfigs"
        ]

        var components = URLComponents(string: Self.authBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "include_granted_scopes", value: "true"),
            URLQueryItem(name: "state", value: state),
        ]
        return components?.url
    }

    /// Exchanges an authorization code for tokens.
    ///
    /// - Parameters:
    ///   - code: Authorization code from Google.
    ///   - redirectURI: Matching redirect URI used in the request.
    /// - Returns: Strongly-typed Sendable token response.
    public func exchangeCode(_ code: String, redirectURI: String) async throws -> GeminiOAuthTokenResponse {
        let params: [String: String] = [
            "client_id": Self.clientID,
            "client_secret": Self.clientSecret,
            "code": code,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        return try await postTokenRequest(params: params)
    }

    /// Refreshes an expired access token using a refresh token.
    ///
    /// - Parameter refreshToken: Stored refresh token.
    /// - Returns: Updated token response with new access token.
    public func refreshAccessToken(refreshToken: String) async throws -> GeminiOAuthTokenResponse {
        let params: [String: String] = [
            "client_id": Self.clientID,
            "client_secret": Self.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        return try await postTokenRequest(params: params)
    }

    /// Retrieves user email and profile name.
    ///
    /// - Parameter accessToken: Valid Google access token.
    /// - Returns: Tuple of (email, name).
    public func fetchUserInfo(accessToken: String) async throws -> (email: String, name: String?) {
        var req = URLRequest(url: Self.userInfoURL)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(GeminiEndpoints.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        let name = json["name"] as? String
        return (email, name)
    }

    private func postTokenRequest(params: [String: String]) async throws -> GeminiOAuthTokenResponse {
        var req = URLRequest(url: Self.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(GeminiEndpoints.userAgent, forHTTPHeaderField: "User-Agent")

        let bodyString = params.map { "\($0.key)=\(Self.urlEncode($0.value))" }.joined(separator: "&")
        req.httpBody = Data(bodyString.utf8)

        let (data, response) = try await session.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            let errorMsg = json["error_description"] as? String ?? json["error"] as? String ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "GeminiOAuthService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        do {
            return try JSONDecoder().decode(GeminiOAuthTokenResponse.self, from: data)
        } catch {
            throw URLError(.cannotParseResponse)
        }
    }

    private static func urlEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
