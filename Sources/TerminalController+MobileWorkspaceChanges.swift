import Foundation

extension TerminalController {
    @MainActor
    func v2MobileWorkspaceChanges(method: String, params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }

    @MainActor
    func v2MobileWorkspaceChangesSummary(params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }

    @MainActor
    func v2MobileWorkspaceChangesFiles(params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }

    @MainActor
    func v2MobileWorkspaceChangesFileDiff(params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }

    @MainActor
    func v2MobileWorkspaceChangesFileStat(params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }

    @MainActor
    func v2MobileWorkspaceChangesFileFetch(params: [String: Any]) async -> V2CallResult {
        .err(code: "capability_disabled", message: "Workspace changes are not enabled in local build", data: nil)
    }
}
