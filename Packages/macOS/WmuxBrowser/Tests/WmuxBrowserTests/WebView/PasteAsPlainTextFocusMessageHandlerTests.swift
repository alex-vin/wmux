import Foundation
import Testing

@testable import WmuxBrowser

@Suite("Browser paste focus message boundary")
struct PasteAsPlainTextFocusMessageHandlerTests {
    /// The parser rejects values that cannot safely drive the paste state.
    @Test("accepts only a boolean canPaste payload")
    func parsesPayloadConservatively() {
        #expect(WmuxWebView.pasteAsPlainTextTargetAvailable(from: ["canPaste": true]) == true)
        #expect(WmuxWebView.pasteAsPlainTextTargetAvailable(from: ["canPaste": false]) == false)
        #expect(WmuxWebView.pasteAsPlainTextTargetAvailable(from: ["canPaste": "true"]) == nil)
        #expect(WmuxWebView.pasteAsPlainTextTargetAvailable(from: ["other": true]) == nil)
        #expect(WmuxWebView.pasteAsPlainTextTargetAvailable(from: NSNull()) == nil)
    }

    /// The callback boundary delivers valid payloads through MainActor.
    @Test("schedules valid payload updates on MainActor")
    func schedulesPayloadUpdate() async {
        let delivered = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            WmuxWebView.schedulePasteAsPlainTextTargetUpdate(from: ["canPaste": true]) { canPaste in
                continuation.resume(returning: canPaste)
            }
        }

        #expect(delivered)
    }
}
