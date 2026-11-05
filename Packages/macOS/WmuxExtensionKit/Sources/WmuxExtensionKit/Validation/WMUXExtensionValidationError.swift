import Foundation

@_spi(WmuxHostTransport)
public enum WmuxExtensionValidationError: Error, Equatable, Sendable {
    case unsupportedAPIVersion(requested: WmuxExtensionAPIVersion, supported: WmuxExtensionAPIVersion)
    case emptyIdentifier
    case emptyDisplayName
    case payloadTooLarge(kind: String, actualBytes: Int, maximumBytes: Int)
}
