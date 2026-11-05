import WmuxCloud
import WMUXAuthCore
import WmuxAuthRuntime
import Foundation
import Testing
import os

#if canImport(wmux_DEV)
@testable import wmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@MainActor
struct CloudRefreshFixture {
    let client: VMClient
    let auth: AuthCoordinator
    let session: URLSession
    let readRequests: CloudReadRequestCoordinator

    static func make(
        readRequests: CloudReadRequestCoordinator = CloudReadRequestCoordinator(),
        authClient: (any AuthClient)? = nil,
        isDisabledByManagedPolicy: (@Sendable () -> Bool)? = nil,
        isCloudEnabled: @escaping @Sendable () -> Bool = { true },
        fixtureTeams: Bool = false,
        requestBudget: CloudRequestBudget = .live
    ) async throws -> Self {
        let defaults = try #require(UserDefaults(suiteName: "CloudRefreshFixture.\(UUID())"))
        let auth = AuthCoordinator(
            client: authClient ?? CloudRefreshAuthClient(),
            sessionCache: WMUXAuthSessionCache(keyValueStore: defaults, key: "session"),
            userCache: WMUXAuthIdentityStore(keyValueStore: defaults, key: "user"),
            teamSelection: WMUXAuthTeamSelectionStore(keyValueStore: defaults, key: "team"),
            anchor: AuthPresentationContextProvider(),
            config: AuthConfig(
                stack: WMUXAuthConfig(projectId: "fixture", publishableClientKey: "fixture"),
                magicLinkCallbackURL: "http://127.0.0.1:1/callback", apiBaseURL: "http://127.0.0.1:1"
            ),
            launch: AuthLaunchOptions(
                clearAuthRequested: false, mockDataEnabled: false,
                environment: [
                    "WMUX_UITEST_AUTH_FIXTURE": "1", "WMUX_UITEST_AUTH_USER_ID": "fixture",
                ].merging(fixtureTeams ? ["WMUX_UITEST_AUTH_FIXTURE_TEAMS": "1"] : [:]) { current, _ in current },
                includesDevAuth: true
            )
        )
        auth.start()
        await auth.awaitBootstrapped()
        try #require(auth.isAuthenticated)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CloudRefreshURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return Self(client: VMClient(
            session: session, auth: auth, resourceStats: VMResourceStatsStore(), checkpointRenames: CloudRenameCoordinator(),
            machineCache: CloudMachineCache(defaults: defaults), isDisabledByManagedPolicy: isDisabledByManagedPolicy,
            readRequests: readRequests, isCloudEnabled: isCloudEnabled, requestBudget: requestBudget
        ), auth: auth, session: session, readRequests: readRequests)
    }
}
