public struct KeyDefinition: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let virtualKeyCode: UInt16
    public let hidUsage: UInt64
    public let row: Int
    public let width: Double
    public let isModifier: Bool

    public init(id: String, label: String, virtualKeyCode: UInt16, hidUsage: UInt64,
                row: Int, width: Double = 1.0, isModifier: Bool = false) {
        self.id = id
        self.label = label
        self.virtualKeyCode = virtualKeyCode
        self.hidUsage = hidUsage
        self.row = row
        self.width = width
        self.isModifier = isModifier
    }
}
