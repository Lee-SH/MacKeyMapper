public struct KeyMapping: Codable, Equatable, Identifiable, Sendable {
    public let sourceKeyID: String
    public let destKeyID: String
    public var id: String { "\(sourceKeyID)->\(destKeyID)" }

    public init(sourceKeyID: String, destKeyID: String) {
        self.sourceKeyID = sourceKeyID
        self.destKeyID = destKeyID
    }
}

public enum MappingError: Error, Equatable {
    case selfMapping(keyID: String)
    case duplicateSource(keyID: String)
    case unknownKey(keyID: String)
}

public func validateMappings(_ mappings: [KeyMapping],
                             catalog: [KeyDefinition] = KeyCatalog.keys) throws {
    let ids = Set(catalog.map(\.id))
    var seenSources = Set<String>()
    for m in mappings {
        guard ids.contains(m.sourceKeyID) else { throw MappingError.unknownKey(keyID: m.sourceKeyID) }
        guard ids.contains(m.destKeyID) else { throw MappingError.unknownKey(keyID: m.destKeyID) }
        if m.sourceKeyID == m.destKeyID { throw MappingError.selfMapping(keyID: m.sourceKeyID) }
        if seenSources.contains(m.sourceKeyID) { throw MappingError.duplicateSource(keyID: m.sourceKeyID) }
        seenSources.insert(m.sourceKeyID)
    }
}
