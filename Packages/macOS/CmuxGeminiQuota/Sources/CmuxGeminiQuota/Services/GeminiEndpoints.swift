public import Foundation

/// Defines standard endpoints and headers for Google Cloud Code / Code Assist quota services.
public struct GeminiEndpoints: Sendable {
    /// User agent string mimicking Antigravity.
    public static let userAgent = "vscode/1.X.X (Antigravity/4.9.6)"

    /// Fallback URLs for fetching available models.
    public static let fetchAvailableModels: [URL] = [
        URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels")!,
        URL(string: "https://daily-cloudcode-pa.sandbox.googleapis.com/v1internal:fetchAvailableModels")!,
        URL(string: "https://cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels")!,
    ]

    /// Fallback URLs for retrieving user quota summary.
    public static let retrieveUserQuotaSummary: [URL] = [
        URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary")!,
        URL(string: "https://daily-cloudcode-pa.sandbox.googleapis.com/v1internal:retrieveUserQuotaSummary")!,
        URL(string: "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary")!,
    ]

    /// Fallback URLs for loading Code Assist metadata and project id.
    public static let loadCodeAssist: [URL] = [
        URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal:loadCodeAssist")!,
        URL(string: "https://daily-cloudcode-pa.sandbox.googleapis.com/v1internal:loadCodeAssist")!,
        URL(string: "https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist")!,
    ]
}
