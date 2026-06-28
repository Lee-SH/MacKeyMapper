import XCTest
@testable import MacKeyMapperCore

final class ScannedKeyboardTests: XCTestCase {
    private let sample = ScannedKeyboard(keys: [
        ScannedKey(slotID: "a", keyCode: 0, character: "a", present: true),
        ScannedKey(slotID: "escape", keyCode: 53, character: "", present: true),
        ScannedKey(slotID: "menu", keyCode: 0, character: "", present: false),
    ])

    func testKeyForSlotID() {
        XCTAssertEqual(sample.key(forSlotID: "a")?.character, "a")
        XCTAssertNil(sample.key(forSlotID: "missing"))
    }

    func testKeyForKeyCodeReturnsPresentMatch() {
        XCTAssertEqual(sample.key(forKeyCode: 53)?.slotID, "escape")
    }

    func testKeyForKeyCodeIgnoresAbsentSlots() {
        // absent slots have keyCode 0; a real keyCode 0 ("a") must win over absent ones
        XCTAssertEqual(sample.key(forKeyCode: 0)?.slotID, "a")
    }
}
