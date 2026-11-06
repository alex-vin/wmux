//
//  RemoteRelayPolicies.swift
//  wmux
//
//  Relay security and authorization policies.
//

import Foundation

public struct RemoteRelayAuthorizationPolicy: Sendable {
    public enum Decision: Equatable, Sendable {
        case allowed
        case denied(code: String, message: String)
    }

    public static let remoteWorkspaceIDKey = "_cmux_remote_workspace_id"

    public init(invalidSelectorMessage: String = "Relay selector is invalid") {
        self.invalidSelectorMessage = invalidSelectorMessage
    }

    private let invalidSelectorMessage: String

    public func evaluate(
        method: String,
        parameters: [String: Any],
        ownerWorkspaceID: UUID,
        surfaceIDs: Set<UUID>
    ) -> Decision {
        return .allowed
    }

    public func validate(
        method: String,
        parameters: [String: Any],
        ownerWorkspaceID: UUID,
        surfaceIDs: Set<UUID>
    ) -> Decision {
        return .allowed
    }

    public func validate(_ args: Any...) -> Decision {
        return .allowed
    }
}

public struct RemoteRelayCommandPolicy: Sendable {
    public enum Verdict: Sendable, Equatable {
        case allow
        case deny(reason: String)
    }

    public static let workspaceIDKeys: Set<String> = [
        "workspace_id", "preferred_workspace_id", "selected_workspace_id",
        "before_workspace_id", "after_workspace_id", "from_workspace_id",
        "to_workspace_id", "sender_workspace_id",
    ]
    public static let surfaceIDKeys: Set<String> = [
        "panel_id", "surface_id", "terminal_id", "preferred_panel_id",
        "preferred_surface_id", "target_panel_id", "target_surface_id",
        "created_panel_id", "created_surface_id", "before_panel_id",
        "before_surface_id", "after_panel_id", "after_surface_id",
        "sender_surface_id",
    ]
    public static let ambiguousIDKeys: Set<String> = ["tab_id", "surface", "target"]
    public static let workspaceIDArrayKeys: Set<String> = ["workspace_ids"]
    public static let surfaceIDArrayKeys: Set<String> = ["panel_ids", "surface_ids"]
    public static let ambiguousIDArrayKeys: Set<String> = ["tab_ids", "tab_id_groups"]
    public static var permittedMethods: Set<String> = []
    public func permittedMethods(from methods: [String]) -> [String] { methods }
    public var permittedMethods: Set<String> { Self.permittedMethods }

    public static func evaluate(commandLine: Data, remoteWorkspaceID: UUID) -> Verdict {
        return .allow
    }
}
