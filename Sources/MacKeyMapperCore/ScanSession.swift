public struct ScanSession: Equatable {
    public let slots: [ScanSlot]
    public private(set) var index: Int
    public private(set) var captured: [ScannedKey]

    public init(slots: [ScanSlot] = ScanTemplate.slots) {
        self.slots = slots
        self.index = 0
        self.captured = []
    }

    public var currentSlot: ScanSlot? {
        index < slots.count ? slots[index] : nil
    }

    public var isComplete: Bool {
        index >= slots.count
    }

    public mutating func record(keyCode: UInt16, character: String) {
        guard index < slots.count else { return }
        captured.append(ScannedKey(slotID: slots[index].id, keyCode: keyCode,
                                    character: character, present: true))
        index += 1
    }

    public mutating func skip() {
        guard index < slots.count else { return }
        captured.append(ScannedKey(slotID: slots[index].id, keyCode: 0,
                                    character: "", present: false))
        index += 1
    }

    public mutating func back() {
        guard index > 0 else { return }
        index -= 1
        if !captured.isEmpty { captured.removeLast() }
    }

    public func result() -> ScannedKeyboard {
        ScannedKeyboard(keys: captured)
    }
}
