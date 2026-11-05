import Foundation
@testable import WmuxTerminal

@MainActor
final class FakeRendererRealizationScheduler: TerminalRendererRealizationScheduling {
    private(set) var scheduledSurfaceIDs: [UUID] = []
    var onSchedule: ((UUID) -> Void)?

    func scheduleRendererPresentationRepair(surfaceID: UUID) {
        scheduledSurfaceIDs.append(surfaceID)
        onSchedule?(surfaceID)
    }
}
