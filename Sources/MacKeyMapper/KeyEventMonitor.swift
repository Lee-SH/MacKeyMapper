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
            let code = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            event.keyboardGetUnicodeString(maxStringLength: 4,
                                           actualStringLength: &length,
                                           unicodeString: &chars)
            let characters = String(utf16CodeUnits: chars, count: length)
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            switch type {
            case .keyDown:      if !isRepeat { monitor.onEvent?(code, true, false, characters) }
            case .keyUp:        monitor.onEvent?(code, false, false, characters)
            case .flagsChanged: monitor.onEvent?(code, false, true, "")
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
}
