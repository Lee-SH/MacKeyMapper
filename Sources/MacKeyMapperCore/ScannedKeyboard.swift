public struct ScannedKey: Codable, Equatable, Sendable {
    public let slotID: String
    public let keyCode: UInt16
    public let character: String
    public let present: Bool

    public init(slotID: String, keyCode: UInt16, character: String, present: Bool) {
        self.slotID = slotID
        self.keyCode = keyCode
        self.character = character
        self.present = present
    }
}

public struct ScannedKeyboard: Codable, Equatable, Sendable {
    public var keys: [ScannedKey]

    public init(keys: [ScannedKey] = []) {
        self.keys = keys
    }

    public func key(forSlotID id: String) -> ScannedKey? {
        keys.first { $0.slotID == id }
    }

    public func key(forKeyCode code: UInt16) -> ScannedKey? {
        keys.first { $0.present && $0.keyCode == code }
    }
}
