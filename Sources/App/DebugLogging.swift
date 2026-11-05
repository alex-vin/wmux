#if DEBUG
import WMUXDebugLog

@inline(__always)
func cmuxDebugLog(_ message: @autoclosure () -> String) {
    WMUXDebugLog.logDebugEvent(message())
}
#endif
