import CoreGraphics
import Foundation

/// Detects keyDown/keyUp/flagsChanged in listen-only mode via a CGEventTap.
/// Callback signature: (virtualKeyCode, isDown, isModifier, producedCharacter)
final class KeyEventMonitor {
    var onEvent: ((UInt16, Bool, Bool, String) -> Void)?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard tap == nil else { return }
        let mask = (1 << CGEventType.keyDown.rawValue)
                 | (1 << CGEventType.keyUp.rawValue)
                 | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
            // The system can disable a tap (timeout or user input); we must re-enable it,
            // otherwise it goes silent and no further key events are delivered.
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let t = monitor.tap { CGEvent.tapEnable(tap: t, enable: true) }
                return Unmanaged.passUnretained(event)
            }
            let code = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            switch type {
            // Only key-down needs the produced character (for scan capture); compute it there
            // so keyboardGetUnicodeString isn't invoked for flagsChanged (undefined for it).
            case .keyDown:      if !isRepeat { monitor.onEvent?(code, true, false, KeyEventMonitor.characters(from: event)) }
            case .keyUp:        monitor.onEvent?(code, false, false, "")
            case .flagsChanged: monitor.onEvent?(code, false, true, "")  // modifiers produce no character
            default:            break
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private static func characters(from event: CGEvent) -> String {
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        return String(utf16CodeUnits: chars, count: length)
    }
}
