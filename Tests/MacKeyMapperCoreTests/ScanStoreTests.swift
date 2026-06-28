import XCTest
@testable import MacKeyMapperCore

final class ScanStoreTests: XCTestCase {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("mkm-scan-test-\(UUID().uuidString)")
            .appendingPathComponent("scanned-keyboard.json")
    }

    func testLoadNonexistentReturnsNil() throws {
        let store = ScanStore(fileURL: tempURL())
        XCTAssertNil(try store.load())
    }

    func testSaveThenLoadRoundtrips() throws {
        let url = tempURL()
        let store = ScanStore(fileURL: url)
        let board = ScannedKeyboard(keys: [
            ScannedKey(slotID: "escape", keyCode: 53, character: "", present: true),
            ScannedKey(slotID: "a", keyCode: 0, character: "a", present: true),
            ScannedKey(slotID: "menu", keyCode: 0, character: "", present: false),
        ])
        try store.save(board)
        XCTAssertEqual(try store.load(), board)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    func testDefaultURLEndsCorrectly() {
        XCTAssertTrue(ScanStore.defaultURL().path.hasSuffix("MacKeyMapper/scanned-keyboard.json"))
    }
}
