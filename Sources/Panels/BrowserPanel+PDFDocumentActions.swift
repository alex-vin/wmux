import AppKit
import WmuxBrowser
import Foundation

extension BrowserPanel {
    func downloadRenderedPDFDocument() {
        guard let url = renderedPDFDocumentURL else {
            NSSound.beep()
            return
        }
        guard let webView = webView as? WmuxWebView else {
            NSSound.beep()
            return
        }
        let traceID = WmuxWebView.makeContextDownloadTraceID(prefix: "pdfdl")
        webView.downloadURLViaSession(
            url,
            suggestedFilename: nil,
            sender: nil,
            fallbackAction: nil,
            fallbackTarget: nil,
            traceID: traceID
        )
    }

    func printRenderedPDFDocument() {
        guard renderedPDFDocumentURL != nil else {
            NSSound.beep()
            return
        }
        webView.cmuxRunPrintOperation()
    }
}
