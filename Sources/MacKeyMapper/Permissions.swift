import AppKit
import IOKit.hid

enum Permissions {
    /// A listen-only keyboard event tap is gated by **Input Monitoring** (not Accessibility).
    /// Without it the tap is created but key-down events are withheld by the system.
    static func isInputMonitoringGranted() -> Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    /// Triggers the one-time system prompt and registers the app in the Input Monitoring
    /// list so the user can enable it. No-op once the user has already decided.
    @discardableResult
    static func requestInputMonitoring() -> Bool {
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    static func promptAndOpenSettings() {
        requestInputMonitoring()
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
