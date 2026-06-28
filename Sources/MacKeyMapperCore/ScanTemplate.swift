public struct ScanSlot: Identifiable, Equatable, Sendable {
    public let id: String
    public let macLabel: String      // primary symbol/label, e.g. "⌘"
    public let macName: String?      // secondary name, e.g. "command" or "(no Mac equivalent)"
    public let row: Int
    public let width: Double

    public init(id: String, macLabel: String, macName: String? = nil, row: Int, width: Double = 1.0) {
        self.id = id
        self.macLabel = macLabel
        self.macName = macName
        self.row = row
        self.width = width
    }
}

public enum ScanTemplate {
    /// Ordered scan prompt order = layout order. Rows 0–4 reuse the Mac catalog
    /// positions/names; row 5 is a PC-style bottom row with extra PC/Korean keys.
    public static let slots: [ScanSlot] = {
        let upper = KeyCatalog.keys
            .filter { $0.row < 5 }
            .map { ScanSlot(id: $0.id, macLabel: $0.label, macName: $0.name, row: $0.row, width: $0.width) }
        let bottom: [ScanSlot] = [
            ScanSlot(id: "leftControl", macLabel: "⌃", macName: "control", row: 5, width: 1.25),
            ScanSlot(id: "leftWin", macLabel: "⌘", macName: "command (Win)", row: 5, width: 1.25),
            ScanSlot(id: "leftAlt", macLabel: "⌥", macName: "option (Alt)", row: 5, width: 1.25),
            ScanSlot(id: "hanja", macLabel: "한자", macName: "(no Mac equivalent)", row: 5, width: 1.25),
            ScanSlot(id: "space", macLabel: "space", macName: nil, row: 5, width: 5.0),
            ScanSlot(id: "hanyeong", macLabel: "한/영", macName: "(no Mac equivalent)", row: 5, width: 1.25),
            ScanSlot(id: "rightAlt", macLabel: "⌥", macName: "option (Alt)", row: 5, width: 1.25),
            ScanSlot(id: "rightWin", macLabel: "⌘", macName: "command (Win)", row: 5, width: 1.25),
            ScanSlot(id: "menu", macLabel: "▤", macName: "menu (no Mac equivalent)", row: 5, width: 1.25),
            ScanSlot(id: "rightControl", macLabel: "⌃", macName: "control", row: 5, width: 1.25),
        ]
        return upper + bottom
    }()

    public static func slot(id: String) -> ScanSlot? {
        slots.first { $0.id == id }
    }
}
