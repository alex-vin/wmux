import Foundation

enum ControlSidebarAgentLifecycleRegistryScope: Sendable {
    case project(String?)
    case globalOnly

    func loadRegistry(
        homeDirectory: String = NSHomeDirectory(),
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> WmuxVaultAgentRegistry {
        switch self {
        case .project(let workingDirectory):
            return WmuxVaultAgentRegistry.load(
                homeDirectory: homeDirectory,
                workingDirectory: workingDirectory,
                environment: environment,
                fileManager: fileManager
            )
        case .globalOnly:
            return WmuxVaultAgentRegistry.load(
                homeDirectory: homeDirectory,
                environment: [:],
                fileManager: fileManager
            )
        }
    }
}
