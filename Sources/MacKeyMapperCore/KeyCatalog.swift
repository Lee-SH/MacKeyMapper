public enum KeyCatalog {
    // hidUsage = 0x700000000 | (USB HID Keyboard/Keypad usage)
    public static let keys: [KeyDefinition] = [
        // Row 0 — function row
        .init(id: "escape", label: "esc", virtualKeyCode: 53, hidUsage: 0x700000000 | 0x29, row: 0, width: 1.5),
        .init(id: "f1", label: "F1", virtualKeyCode: 122, hidUsage: 0x700000000 | 0x3A, row: 0),
        .init(id: "f2", label: "F2", virtualKeyCode: 120, hidUsage: 0x700000000 | 0x3B, row: 0),
        .init(id: "f3", label: "F3", virtualKeyCode: 99,  hidUsage: 0x700000000 | 0x3C, row: 0),
        .init(id: "f4", label: "F4", virtualKeyCode: 118, hidUsage: 0x700000000 | 0x3D, row: 0),
        .init(id: "f5", label: "F5", virtualKeyCode: 96,  hidUsage: 0x700000000 | 0x3E, row: 0),
        .init(id: "f6", label: "F6", virtualKeyCode: 97,  hidUsage: 0x700000000 | 0x3F, row: 0),
        .init(id: "f7", label: "F7", virtualKeyCode: 98,  hidUsage: 0x700000000 | 0x40, row: 0),
        .init(id: "f8", label: "F8", virtualKeyCode: 100, hidUsage: 0x700000000 | 0x41, row: 0),
        .init(id: "f9", label: "F9", virtualKeyCode: 101, hidUsage: 0x700000000 | 0x42, row: 0),
        .init(id: "f10", label: "F10", virtualKeyCode: 109, hidUsage: 0x700000000 | 0x43, row: 0),
        .init(id: "f11", label: "F11", virtualKeyCode: 103, hidUsage: 0x700000000 | 0x44, row: 0),
        .init(id: "f12", label: "F12", virtualKeyCode: 111, hidUsage: 0x700000000 | 0x45, row: 0),

        // Row 1 — number row
        .init(id: "grave", label: "`", virtualKeyCode: 50, hidUsage: 0x700000000 | 0x35, row: 1),
        .init(id: "n1", label: "1", virtualKeyCode: 18, hidUsage: 0x700000000 | 0x1E, row: 1),
        .init(id: "n2", label: "2", virtualKeyCode: 19, hidUsage: 0x700000000 | 0x1F, row: 1),
        .init(id: "n3", label: "3", virtualKeyCode: 20, hidUsage: 0x700000000 | 0x20, row: 1),
        .init(id: "n4", label: "4", virtualKeyCode: 21, hidUsage: 0x700000000 | 0x21, row: 1),
        .init(id: "n5", label: "5", virtualKeyCode: 23, hidUsage: 0x700000000 | 0x22, row: 1),
        .init(id: "n6", label: "6", virtualKeyCode: 22, hidUsage: 0x700000000 | 0x23, row: 1),
        .init(id: "n7", label: "7", virtualKeyCode: 26, hidUsage: 0x700000000 | 0x24, row: 1),
        .init(id: "n8", label: "8", virtualKeyCode: 28, hidUsage: 0x700000000 | 0x25, row: 1),
        .init(id: "n9", label: "9", virtualKeyCode: 25, hidUsage: 0x700000000 | 0x26, row: 1),
        .init(id: "n0", label: "0", virtualKeyCode: 29, hidUsage: 0x700000000 | 0x27, row: 1),
        .init(id: "minus", label: "-", virtualKeyCode: 27, hidUsage: 0x700000000 | 0x2D, row: 1),
        .init(id: "equal", label: "=", virtualKeyCode: 24, hidUsage: 0x700000000 | 0x2E, row: 1),
        .init(id: "delete", label: "⌫", virtualKeyCode: 51, hidUsage: 0x700000000 | 0x2A, row: 1, width: 2.0),

        // Row 2 — QWERTY
        .init(id: "tab", label: "⇥", virtualKeyCode: 48, hidUsage: 0x700000000 | 0x2B, row: 2, width: 1.5),
        .init(id: "q", label: "Q", virtualKeyCode: 12, hidUsage: 0x700000000 | 0x14, row: 2),
        .init(id: "w", label: "W", virtualKeyCode: 13, hidUsage: 0x700000000 | 0x1A, row: 2),
        .init(id: "e", label: "E", virtualKeyCode: 14, hidUsage: 0x700000000 | 0x08, row: 2),
        .init(id: "r", label: "R", virtualKeyCode: 15, hidUsage: 0x700000000 | 0x15, row: 2),
        .init(id: "t", label: "T", virtualKeyCode: 17, hidUsage: 0x700000000 | 0x17, row: 2),
        .init(id: "y", label: "Y", virtualKeyCode: 16, hidUsage: 0x700000000 | 0x1C, row: 2),
        .init(id: "u", label: "U", virtualKeyCode: 32, hidUsage: 0x700000000 | 0x18, row: 2),
        .init(id: "i", label: "I", virtualKeyCode: 34, hidUsage: 0x700000000 | 0x0C, row: 2),
        .init(id: "o", label: "O", virtualKeyCode: 31, hidUsage: 0x700000000 | 0x12, row: 2),
        .init(id: "p", label: "P", virtualKeyCode: 35, hidUsage: 0x700000000 | 0x13, row: 2),
        .init(id: "leftBracket", label: "[", virtualKeyCode: 33, hidUsage: 0x700000000 | 0x2F, row: 2),
        .init(id: "rightBracket", label: "]", virtualKeyCode: 30, hidUsage: 0x700000000 | 0x30, row: 2),
        .init(id: "backslash", label: "\\", virtualKeyCode: 42, hidUsage: 0x700000000 | 0x31, row: 2, width: 1.5),

        // Row 3 — home row
        .init(id: "capsLock", label: "⇪", name: "caps lock", virtualKeyCode: 57, hidUsage: 0x700000000 | 0x39, row: 3, width: 1.75, isModifier: true),
        .init(id: "a", label: "A", virtualKeyCode: 0, hidUsage: 0x700000000 | 0x04, row: 3),
        .init(id: "s", label: "S", virtualKeyCode: 1, hidUsage: 0x700000000 | 0x16, row: 3),
        .init(id: "d", label: "D", virtualKeyCode: 2, hidUsage: 0x700000000 | 0x07, row: 3),
        .init(id: "f", label: "F", virtualKeyCode: 3, hidUsage: 0x700000000 | 0x09, row: 3),
        .init(id: "g", label: "G", virtualKeyCode: 5, hidUsage: 0x700000000 | 0x0A, row: 3),
        .init(id: "h", label: "H", virtualKeyCode: 4, hidUsage: 0x700000000 | 0x0B, row: 3),
        .init(id: "j", label: "J", virtualKeyCode: 38, hidUsage: 0x700000000 | 0x0D, row: 3),
        .init(id: "k", label: "K", virtualKeyCode: 40, hidUsage: 0x700000000 | 0x0E, row: 3),
        .init(id: "l", label: "L", virtualKeyCode: 37, hidUsage: 0x700000000 | 0x0F, row: 3),
        .init(id: "semicolon", label: ";", virtualKeyCode: 41, hidUsage: 0x700000000 | 0x33, row: 3),
        .init(id: "quote", label: "'", virtualKeyCode: 39, hidUsage: 0x700000000 | 0x34, row: 3),
        .init(id: "return", label: "⏎", virtualKeyCode: 36, hidUsage: 0x700000000 | 0x28, row: 3, width: 2.25),

        // Row 4 — bottom letter row
        .init(id: "leftShift", label: "⇧", name: "L shift", virtualKeyCode: 56, hidUsage: 0x700000000 | 0xE1, row: 4, width: 2.25, isModifier: true),
        .init(id: "z", label: "Z", virtualKeyCode: 6, hidUsage: 0x700000000 | 0x1D, row: 4),
        .init(id: "x", label: "X", virtualKeyCode: 7, hidUsage: 0x700000000 | 0x1B, row: 4),
        .init(id: "c", label: "C", virtualKeyCode: 8, hidUsage: 0x700000000 | 0x06, row: 4),
        .init(id: "v", label: "V", virtualKeyCode: 9, hidUsage: 0x700000000 | 0x19, row: 4),
        .init(id: "b", label: "B", virtualKeyCode: 11, hidUsage: 0x700000000 | 0x05, row: 4),
        .init(id: "n", label: "N", virtualKeyCode: 45, hidUsage: 0x700000000 | 0x11, row: 4),
        .init(id: "m", label: "M", virtualKeyCode: 46, hidUsage: 0x700000000 | 0x10, row: 4),
        .init(id: "comma", label: ",", virtualKeyCode: 43, hidUsage: 0x700000000 | 0x36, row: 4),
        .init(id: "period", label: ".", virtualKeyCode: 47, hidUsage: 0x700000000 | 0x37, row: 4),
        .init(id: "slash", label: "/", virtualKeyCode: 44, hidUsage: 0x700000000 | 0x38, row: 4),
        .init(id: "rightShift", label: "⇧", name: "R shift", virtualKeyCode: 60, hidUsage: 0x700000000 | 0xE5, row: 4, width: 2.75, isModifier: true),

        // Row 5 — modifier row (left/right distinction is essential)
        .init(id: "leftControl", label: "⌃", name: "L control", virtualKeyCode: 59, hidUsage: 0x700000000 | 0xE0, row: 5, width: 1.25, isModifier: true),
        .init(id: "leftOption", label: "⌥", name: "L option", virtualKeyCode: 58, hidUsage: 0x700000000 | 0xE2, row: 5, width: 1.25, isModifier: true),
        .init(id: "leftCommand", label: "⌘", name: "L command", virtualKeyCode: 55, hidUsage: 0x700000000 | 0xE3, row: 5, width: 1.25, isModifier: true),
        .init(id: "space", label: "space", virtualKeyCode: 49, hidUsage: 0x700000000 | 0x2C, row: 5, width: 6.25),
        .init(id: "rightCommand", label: "⌘", name: "R command", virtualKeyCode: 54, hidUsage: 0x700000000 | 0xE7, row: 5, width: 1.25, isModifier: true),
        .init(id: "rightOption", label: "⌥", name: "R option", virtualKeyCode: 61, hidUsage: 0x700000000 | 0xE6, row: 5, width: 1.25, isModifier: true),
        .init(id: "rightControl", label: "⌃", name: "R control", virtualKeyCode: 62, hidUsage: 0x700000000 | 0xE4, row: 5, width: 1.25, isModifier: true),
    ]

    public static func key(id: String) -> KeyDefinition? {
        keys.first { $0.id == id }
    }

    public static func key(forVirtualKeyCode vk: UInt16) -> KeyDefinition? {
        keys.first { $0.virtualKeyCode == vk }
    }
}
