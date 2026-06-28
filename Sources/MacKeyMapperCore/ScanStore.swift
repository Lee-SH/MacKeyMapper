import Foundation

public struct ScanStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("MacKeyMapper/scanned-keyboard.json")
    }

    /// Returns nil when no scan has been saved yet.
    public func load() throws -> ScannedKeyboard? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ScannedKeyboard.self, from: data)
    }

    public func save(_ board: ScannedKeyboard) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(board)
        try data.write(to: fileURL, options: .atomic)
    }
}
