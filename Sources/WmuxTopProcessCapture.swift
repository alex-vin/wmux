import WmuxFoundation

/// Keeps census identities attached to its immutable projection for later enrichment.
struct WmuxTopProcessCapture: Sendable {
    let listing: DarwinProcessListing
    let snapshot: WmuxTopProcessSnapshot
    let fields: WmuxTopProcessFields
}
