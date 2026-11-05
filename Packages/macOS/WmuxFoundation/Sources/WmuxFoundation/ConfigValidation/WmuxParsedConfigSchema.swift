import Foundation

/// A deserialized cmux.json schema that validators share instead of re-parsing.
///
/// The tree is never mutated after parsing, so concurrent reads are safe.
struct WmuxParsedConfigSchema: @unchecked Sendable {
    /// The schema embedded in WmuxFoundation, parsed on first use.
    static let embedded = WmuxParsedConfigSchema(data: WmuxEmbeddedConfigSchema.data)

    let root: [String: Any]

    init(data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any] else {
            preconditionFailure("wmux.json schema is not a JSON object")
        }
        self.root = root
    }
}
