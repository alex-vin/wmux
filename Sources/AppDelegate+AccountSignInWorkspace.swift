import AppKit

extension AppDelegate {
    /// Opens the shared Stack sign-in flow in a dedicated workspace pane.
    @discardableResult
    func performAccountSignInWorkspaceAction(
        tabManager preferredTabManager: TabManager? = nil,
        preferredWindow: NSWindow? = nil,
        debugSource: String = "accountSignIn"
    ) -> Bool {
        return false
    }
}
