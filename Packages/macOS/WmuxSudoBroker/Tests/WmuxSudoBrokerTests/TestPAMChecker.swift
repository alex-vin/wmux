@testable import WmuxSudoBroker

struct TestPAMChecker: SudoPAMChecking {
    let enabled: Bool

    func touchIDIsEnabled() -> Bool { enabled }
}
