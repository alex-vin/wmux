public import Foundation

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
    /// - Returns: Raw JSON dictionary containing access_token, refresh_token, id_token, expires_in.
    public func exchangeCode(_ code: String, redirectURI: String) async throws -> [String: Any] {
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
    /// - Returns: Updated token dictionary with new access_token and expires_in.
    public func refreshAccessToken(refreshToken: String) async throws -> [String: Any] {
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

    private func postTokenRequest(params: [String: String]) async throws -> [String: Any] {
        var req = URLRequest(url: Self.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(GeminiEndpoints.userAgent, forHTTPHeaderField: "User-Agent")

        let bodyString = params.map { "\($0.key)=\(Self.urlEncode($0.value))" }.joined(separator: "&")
        req.httpBody = Data(bodyString.utf8)

        let (data, response) = try await session.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let errorMsg = json["error_description"] as? String ?? json["error"] as? String ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "GeminiOAuthService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        return json
    }

    private static func urlEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
