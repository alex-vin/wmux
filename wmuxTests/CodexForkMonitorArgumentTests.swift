import Foundation
import Testing
import WMUXAgentLaunch

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

struct CodexForkMonitorArgumentTests {
    @Test
    func forwardsForkParentClaimToDetachedMonitor() {
        let arguments = CodexForkMonitorArguments().make(environment: [
            "WMUX_AGENT_FORK_PARENT_SESSION_ID": "parent-session",
            "WMUX_AGENT_FORK_LAUNCH_ID": "launch-id",
            "WMUX_CODEX_PID": "1234",
        ])

        #expect(arguments == [
            "--fork-parent", "parent-session",
            "--fork-launch-id", "launch-id",
            "--fork-owner-pid", "1234",
        ])
    }

    @Test
    func omitsForkArgumentsForNormalCodexMonitor() {
        #expect(CodexForkMonitorArguments().make(environment: [:]).isEmpty)
    }
    @Test
    func omitsForkArgumentsWithoutValidParent() {
        for parent in [String?.none, ""] {
            var environment = ["WMUX_AGENT_FORK_LAUNCH_ID": "launch-id", "WMUX_CODEX_PID": "1234"]
            environment["WMUX_AGENT_FORK_PARENT_SESSION_ID"] = parent
            #expect(WmuxTuiRemoteRouting.codexForkMonitorArguments(environment: environment).isEmpty)
        }
    }

    @Test
    func omitsEmptyOptionalForkMetadata() {
        #expect(WmuxTuiRemoteRouting.codexForkMonitorArguments(environment: [
            "WMUX_AGENT_FORK_PARENT_SESSION_ID": "parent-session",
            "WMUX_AGENT_FORK_LAUNCH_ID": "",
            "WMUX_CODEX_PID": "",
        ]) == ["--fork-parent", "parent-session"])
    }

}
