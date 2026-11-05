import WmuxTerminalCore

/// Lets `WmuxConfigStoreReloadCoordinator` drive per-window config reloads through a
/// protocol seam. `WmuxConfigStore`'s existing `loadAll()` already satisfies the
/// requirement, so this conformance is empty.
extension WmuxConfigStore: WmuxConfigStoreReloading {}
