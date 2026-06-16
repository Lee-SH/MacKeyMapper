import XCTest
@testable import MacKeyMapperCore

final class RemapStoreTests: XCTestCase {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mkm-test-\(UUID().uuidString)")
            .appendingPathComponent("mappings.json")
    }

    func testLoadNonexistentReturnsEmpty() throws {
        let store = RemapStore(fileURL: tempURL())
        XCTAssertEqual(try store.load(), [])
    }

    func testSaveThenLoadRoundtrips() throws {
        let url = tempURL()
        let store = RemapStore(fileURL: url)
        let mappings = [
            KeyMapping(sourceKeyID: "capsLock", destKeyID: "leftControl"),
            KeyMapping(sourceKeyID: "rightOption", destKeyID: "rightCommand"),
        ]
        try store.save(mappings)
        XCTAssertEqual(try store.load(), mappings)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    func testDefaultURLEndsCorrectly() {
        XCTAssertTrue(RemapStore.defaultURL().path.hasSuffix("MacKeyMapper/mappings.json"))
    }
}
