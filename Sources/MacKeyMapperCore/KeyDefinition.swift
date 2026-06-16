public struct KeyDefinition: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    /// 기호 라벨(예: ⌃, ⌘)만으로 식별이 어려운 키에 함께 표시할 이름(예: "control"). 없으면 nil.
    public let name: String?
    public let virtualKeyCode: UInt16
    public let hidUsage: UInt64
    public let row: Int
    public let width: Double
    public let isModifier: Bool

    public init(id: String, label: String, name: String? = nil,
                virtualKeyCode: UInt16, hidUsage: UInt64,
                row: Int, width: Double = 1.0, isModifier: Bool = false) {
        self.id = id
        self.label = label
        self.name = name
        self.virtualKeyCode = virtualKeyCode
        self.hidUsage = hidUsage
        self.row = row
        self.width = width
        self.isModifier = isModifier
    }
}
