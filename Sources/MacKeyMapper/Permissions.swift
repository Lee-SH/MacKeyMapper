@preconcurrency import ApplicationServices
import AppKit

enum Permissions {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptAndOpenSettings() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
