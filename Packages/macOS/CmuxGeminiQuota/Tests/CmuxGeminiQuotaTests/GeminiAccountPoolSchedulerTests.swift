import Foundation
import Testing
@testable import CmuxGeminiQuota

@Suite("GeminiAccountPoolSchedulerTests")
@MainActor
struct GeminiAccountPoolSchedulerTests {
    private func makeTestStore() -> (GeminiAccountStore, URL) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_gemini_\(UUID().uuidString).json")
        let store = GeminiAccountStore(storageURL: tempURL)
        return (store, tempURL)
    }

    private func makeAccount(
        id: String,
        fiveHour: Double,
        weekly: Double,
        isDisabled: Bool = false
    ) -> GeminiAccount {
        let group = GeminiQuotaGroup(displayName: "Gemini", buckets: [
            GeminiQuotaBucket(id: "gemini-5h", window: "5h", remainingFraction: fiveHour),
            GeminiQuotaBucket(id: "gemini-weekly", window: "weekly", remainingFraction: weekly)
        ])
        let model = GeminiModelQuota(id: "gemini-3.8-flash", displayName: "Gemini 3.8 Flash", percentage: Int((fiveHour * 100.0).rounded()))
        let snapshot = GeminiQuotaSnapshot(
            models: [model],
            groups: [group],
            tier: .pro,
            isForbidden: false
        )
        return GeminiAccount(
            id: id,
            email: id,
            quota: snapshot,
            isDisabled: isDisabled
        )
    }

    @Test("Score formula calculation")
    func scoreCalculation() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        // 5h: 80% (0.8), weekly: 70% (0.7), active: 0
        // Score = (80.0 * 0.6) + (70.0 * 0.3) - (0 * 20) = 48.0 + 21.0 = 69.0
        let account = makeAccount(id: "acc1@example.com", fiveHour: 0.8, weekly: 0.7)
        #expect(abs(scheduler.score(for: account) - 69.0) < 0.001)

        // Increment active sessions to 2
        // Score = 69.0 - (2 * 20.0) = 29.0
        scheduler.incrementActive(for: account.id)
        scheduler.incrementActive(for: account.id)
        #expect(scheduler.activeSessionCounts[account.id] == 2)
        #expect(abs(scheduler.score(for: account) - 29.0) < 0.001)

        // Decrement active sessions
        scheduler.decrementActive(for: account.id)
        #expect(scheduler.activeSessionCounts[account.id] == 1)
        #expect(abs(scheduler.score(for: account) - 49.0) < 0.001)

        scheduler.decrementActive(for: account.id)
        #expect(scheduler.activeSessionCounts[account.id] == nil)
        #expect(abs(scheduler.score(for: account) - 69.0) < 0.001)
    }

    @Test("Optimal account selection chooses highest score")
    func optimalAccountSelection() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accA = makeAccount(id: "a@example.com", fiveHour: 0.9, weekly: 0.8) // score = 54 + 24 = 78
        let accB = makeAccount(id: "b@example.com", fiveHour: 0.6, weekly: 0.5) // score = 36 + 15 = 51
        let accC = makeAccount(id: "c@example.com", fiveHour: 0.95, weekly: 0.9) // score = 57 + 27 = 84

        store.addOrUpdateAccount(accA)
        store.addOrUpdateAccount(accB)
        store.addOrUpdateAccount(accC)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        let picked = scheduler.pickOptimalAccount()
        #expect(picked?.id == "c@example.com")
    }

    @Test("Subagent exclusion avoids parent agent collision")
    func subagentExclusion() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accA = makeAccount(id: "parent@example.com", fiveHour: 0.99, weekly: 0.99) // highest score
        let accB = makeAccount(id: "subagent@example.com", fiveHour: 0.8, weekly: 0.8)

        store.addOrUpdateAccount(accA)
        store.addOrUpdateAccount(accB)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        // Without exclusion, parent@ is picked
        #expect(scheduler.pickOptimalAccount()?.id == "parent@example.com")

        // With exclusion of parent account, subagent@ is picked
        let picked = scheduler.pickOptimalAccount(excludingAccountID: "parent@example.com")
        #expect(picked?.id == "subagent@example.com")
    }

    @Test("Subagent exclusion falls back gracefully when no other accounts are available")
    func subagentExclusionFallback() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accA = makeAccount(id: "parent@example.com", fiveHour: 0.9, weekly: 0.9)
        store.addOrUpdateAccount(accA)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        // With only parent account available, excluding it should gracefully fall back to parent
        let picked = scheduler.pickOptimalAccount(excludingAccountID: "parent@example.com")
        #expect(picked?.id == "parent@example.com")
    }

    @Test("Coordinator rebind and unbind correctly pairs active session counts")
    func coordinatorRebindAndUnbind() {
        let (store, tempURL) = makeTestStore()
        let tempAccountsDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_accounts_\(UUID().uuidString)")
        let tempTokensDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_tokens_\(UUID().uuidString)")

        defer {
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.removeItem(at: tempAccountsDir)
            try? FileManager.default.removeItem(at: tempTokensDir)
        }

        let acc1 = makeAccount(id: "acc1@example.com", fiveHour: 0.8, weekly: 0.8)
        let acc2 = makeAccount(id: "acc2@example.com", fiveHour: 0.6, weekly: 0.6)
        store.addOrUpdateAccount(acc1)
        store.addOrUpdateAccount(acc2)

        let coordinator = GeminiTerminalAccountCoordinator(
            accountStore: store,
            accountsBaseDirectory: tempAccountsDir,
            tokenCacheDirectory: tempTokensDir
        )
        let surface = UUID()

        // 1. Manually bind surface to acc1
        coordinator.bind(surfaceID: surface, to: "acc1@example.com")
        #expect(coordinator.surfaceBindings[surface] == "acc1@example.com")
        #expect(coordinator.scheduler.activeSessionCounts["acc1@example.com"] == 1)

        // 2. Re-bind same surface to acc2 (switching account)
        coordinator.bind(surfaceID: surface, to: "acc2@example.com")
        #expect(coordinator.surfaceBindings[surface] == "acc2@example.com")
        #expect(coordinator.scheduler.activeSessionCounts["acc1@example.com"] == nil)
        #expect(coordinator.scheduler.activeSessionCounts["acc2@example.com"] == 1)

        // 3. Unbind surface
        coordinator.unbind(surfaceID: surface)
        #expect(coordinator.surfaceBindings[surface] == nil)
        #expect(coordinator.scheduler.activeSessionCounts["acc2@example.com"] == nil)
    }

    @Test("Cooldown filtering respects timeout duration")
    func cooldownFiltering() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accA = makeAccount(id: "a@example.com", fiveHour: 0.9, weekly: 0.9)
        let accB = makeAccount(id: "b@example.com", fiveHour: 0.7, weekly: 0.7)

        store.addOrUpdateAccount(accA)
        store.addOrUpdateAccount(accB)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        // Mark accA as cooling for 15 minutes
        scheduler.markCooling(accountID: "a@example.com", duration: 900)
        #expect(scheduler.isCooling(accountID: "a@example.com"))

        // Should pick accB because accA is cooling
        #expect(scheduler.pickOptimalAccount()?.id == "b@example.com")

        // Clear cooling on accA -> accA should be picked again
        scheduler.clearCooling(for: "a@example.com")
        #expect(!scheduler.isCooling(accountID: "a@example.com"))
        #expect(scheduler.pickOptimalAccount()?.id == "a@example.com")
    }

    @Test("Weekly quota depletion filter (weekly <= 0.05)")
    func weeklyDepletionFiltering() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accDepleted = makeAccount(id: "depleted@example.com", fiveHour: 0.99, weekly: 0.04) // <= 0.05
        let accBoundary = makeAccount(id: "boundary@example.com", fiveHour: 0.99, weekly: 0.05) // <= 0.05
        let accHealthy = makeAccount(id: "healthy@example.com", fiveHour: 0.50, weekly: 0.06) // > 0.05

        store.addOrUpdateAccount(accDepleted)
        store.addOrUpdateAccount(accBoundary)
        store.addOrUpdateAccount(accHealthy)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        let picked = scheduler.pickOptimalAccount()
        #expect(picked?.id == "healthy@example.com")
    }

    @Test("Disabled and forbidden accounts are filtered")
    func disabledAndForbiddenAccountsFiltered() {
        let (store, tempURL) = makeTestStore()
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let accDisabled = makeAccount(id: "disabled@example.com", fiveHour: 0.9, weekly: 0.9, isDisabled: true)
        var accForbidden = makeAccount(id: "forbidden@example.com", fiveHour: 0.9, weekly: 0.9)
        accForbidden.quota.isForbidden = true
        let accValid = makeAccount(id: "valid@example.com", fiveHour: 0.4, weekly: 0.4)

        store.addOrUpdateAccount(accDisabled)
        store.addOrUpdateAccount(accForbidden)
        store.addOrUpdateAccount(accValid)

        let scheduler = GeminiAccountPoolScheduler(accountStore: store)
        let picked = scheduler.pickOptimalAccount()
        #expect(picked?.id == "valid@example.com")
    }

    @Test("Coordinator bindAuto and release lifecycle")
    func coordinatorLifecycle() {
        let (store, tempURL) = makeTestStore()
        let tempAccountsDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_accounts_\(UUID().uuidString)")
        let tempTokensDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_tokens_\(UUID().uuidString)")

        defer {
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.removeItem(at: tempAccountsDir)
            try? FileManager.default.removeItem(at: tempTokensDir)
        }

        let acc1 = makeAccount(id: "acc1@example.com", fiveHour: 0.8, weekly: 0.8)
        let acc2 = makeAccount(id: "acc2@example.com", fiveHour: 0.6, weekly: 0.6)
        store.addOrUpdateAccount(acc1)
        store.addOrUpdateAccount(acc2)

        let coordinator = GeminiTerminalAccountCoordinator(
            accountStore: store,
            accountsBaseDirectory: tempAccountsDir,
            tokenCacheDirectory: tempTokensDir
        )
        let surface1 = UUID()
        let surface2 = UUID()

        // 1. Auto-bind first surface
        let bound1 = coordinator.bindAuto(surfaceID: surface1)
        #expect(bound1?.id == "acc1@example.com")
        #expect(coordinator.surfaceBindings[surface1] == "acc1@example.com")
        #expect(coordinator.scheduler.activeSessionCounts["acc1@example.com"] == 1)
        #expect(FileManager.default.fileExists(atPath: tempAccountsDir.appendingPathComponent("acc1_at_example_com/.config/cmux").path))

        // 2. Auto-bind second surface (acc1 score now penalized by active terminal -20, so acc2 should be preferred:
        // acc1: 80 * 0.9 - 20 = 52. acc2: 60 * 0.9 = 54 -> acc2 is picked!)
        let bound2 = coordinator.bindAuto(surfaceID: surface2)
        #expect(bound2?.id == "acc2@example.com")
        #expect(coordinator.surfaceBindings[surface2] == "acc2@example.com")
        #expect(coordinator.scheduler.activeSessionCounts["acc2@example.com"] == 1)

        // 3. Release surface 1
        coordinator.release(surfaceID: surface1)
        #expect(coordinator.surfaceBindings[surface1] == nil)
        #expect(coordinator.scheduler.activeSessionCounts["acc1@example.com"] == nil)

        // 4. Release surface 2
        coordinator.release(surfaceID: surface2)
        #expect(coordinator.surfaceBindings[surface2] == nil)
        #expect(coordinator.scheduler.activeSessionCounts["acc2@example.com"] == nil)
    }
}
