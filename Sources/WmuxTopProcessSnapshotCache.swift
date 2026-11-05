import WmuxFoundation
import Foundation

extension WmuxTopProcessSnapshot {
    /// Builds the app-scoped process census authority at the composition root.
    static func makeProcessSnapshotService() -> ProcessSnapshotService<WmuxTopProcessCapture, WmuxTopProcessFields> {
        ProcessSnapshotService(
            capture: { try WmuxTopProcessSampler().capture() },
            enrich: { try WmuxTopProcessSampler().enrich($0, fields: $1) }
        )
    }

    /// Enumerates after this request. An older diagnostic census cannot authorize
    /// lifecycle decisions merely because its enrichment finished more recently.
    static func capture(
        includeProcessDetails: Bool = false,
        includeCMUXScope: Bool = true,
        includeResources: Bool = true,
        service: ProcessSnapshotService<WmuxTopProcessCapture, WmuxTopProcessFields>? = nil
    ) async -> WmuxTopProcessSnapshot {
        await capture(
            fields: WmuxTopProcessFields(details: includeProcessDetails, scope: includeCMUXScope, resources: includeResources),
            freshness: .afterRequest, service: service ?? defaultProcessSnapshotService()
        )
    }

    /// Permits diagnostic reuse only within the explicit age bound from census start.
    static func captureCached(
        includeProcessDetails: Bool = false,
        includeCMUXScope: Bool = true,
        includeResources: Bool = true,
        maximumAge: TimeInterval,
        service: ProcessSnapshotService<WmuxTopProcessCapture, WmuxTopProcessFields>? = nil
    ) async -> WmuxTopProcessSnapshot {
        await capture(
            fields: WmuxTopProcessFields(details: includeProcessDetails, scope: includeCMUXScope, resources: includeResources),
            freshness: .maximumAge(.seconds(max(0, maximumAge))), service: service ?? defaultProcessSnapshotService()
        )
    }

    private static func capture(
        fields: WmuxTopProcessFields, freshness: ProcessSnapshotFreshness,
        service: ProcessSnapshotService<WmuxTopProcessCapture, WmuxTopProcessFields>
    ) async -> WmuxTopProcessSnapshot {
        do {
            return try await service.snapshot(fields: fields, freshness: freshness).snapshot
        } catch {
            // Expiry, cancellation and admission failure are unavailable evidence,
            // never a complete empty machine. Safety callers must fail closed.
            return WmuxTopProcessSnapshot(
                processes: [], sampledAt: Date(), includesProcessDetails: fields.contains(.details),
                includesCMUXScope: fields.contains(.scope), includesResources: fields.contains(.resources),
                enumerationIsComplete: false,
                captureIsAvailable: false
            )
        }
    }

    static func allProcesses(includeProcessDetails: Bool, includeCMUXScope: Bool) async -> [WmuxTopProcessInfo] {
        let snapshot = await capture(includeProcessDetails: includeProcessDetails, includeCMUXScope: includeCMUXScope, includeResources: false)
        return Array(snapshot.processesByPID.values)
    }

    private static func defaultProcessSnapshotService() -> ProcessSnapshotService<WmuxTopProcessCapture, WmuxTopProcessFields> {
        AppDelegate.shared?.processSnapshotService ?? makeProcessSnapshotService()
    }
}
