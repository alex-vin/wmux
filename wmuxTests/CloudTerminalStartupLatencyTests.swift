import WmuxCloud
import Foundation
import Testing

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

/// Regression coverage for the post-#12505 Cloud startup path.
@Suite("Cloud terminal startup latency")
struct CloudTerminalStartupLatencyTests {
    @Test
    func terminalCreationFailuresKeepTheirKnownCause() {
        #expect(CloudDiagnosticFailure.classify(WmuxTuiSurfaceProvider.ProviderError.remoteTabNotFound("tab_source")) == .notFound)
        #expect(CloudDiagnosticFailure.classify(WmuxTuiSurfaceProvider.ProviderError.invalidSnapshot("machine")) == .response)
        #expect(CloudDiagnosticFailure.classify(WmuxTuiSurfaceProvider.ProviderError.terminalAttachTimedOut(
            terminalID: "term_created", failure: .transportUnavailable
        )) == .timeout)
    }

    @Test @MainActor
    func unresolvedSurfaceCannotStartAnAttachStream() {
        let session = CloudTuiManualMirrorSession(
            machineID: "machine",
            terminalID: "term_new-machine",
            remoteSurfaceID: 0,
            onNeedsReconnect: {}
        )
        defer { session.stop() }

        session.reconnect(socketPath: "/tmp/cmux-unresolved-startup.sock")

        #expect(session.phase == .idle)
    }
}
