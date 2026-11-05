import Testing
import WmuxRemoteSession

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite
struct TabManagerBootstrapTests {
    @MainActor
    @Test
    func appBootstrapManagerDoesNotCreateAWorkspaceOrTerminal() {
        let nativeSSHConnectionBroker = NativeSSHConnectionBroker()
        let manager = TabManager.makeAppBootstrap(
            nativeSSHConnectionBroker: nativeSSHConnectionBroker
        )

        #expect(manager.tabs.isEmpty)
        #expect(manager.selectedWorkspace == nil)
        #expect(manager.selectedSurface == nil)
        #expect(manager.nativeSSHConnectionBroker === nativeSSHConnectionBroker)
    }
}
