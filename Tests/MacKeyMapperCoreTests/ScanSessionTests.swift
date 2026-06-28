import XCTest
@testable import MacKeyMapperCore

final class ScanSessionTests: XCTestCase {
    private let slots = [
        ScanSlot(id: "a", macLabel: "A", row: 0),
        ScanSlot(id: "b", macLabel: "B", row: 0),
    ]

    func testRecordAdvancesAndCaptures() {
        var s = ScanSession(slots: slots)
        XCTAssertEqual(s.currentSlot?.id, "a")
        s.record(keyCode: 10, character: "a")
        XCTAssertEqual(s.currentSlot?.id, "b")
        XCTAssertEqual(s.result().key(forSlotID: "a")?.keyCode, 10)
        XCTAssertEqual(s.result().key(forSlotID: "a")?.present, true)
    }

    func testSkipMarksAbsentAndAdvances() {
        var s = ScanSession(slots: slots)
        s.skip()
        XCTAssertEqual(s.currentSlot?.id, "b")
        XCTAssertEqual(s.result().key(forSlotID: "a")?.present, false)
    }

    func testBackRedoesPreviousSlot() {
        var s = ScanSession(slots: slots)
        s.record(keyCode: 10, character: "a")
        s.back()
        XCTAssertEqual(s.currentSlot?.id, "a")
        XCTAssertNil(s.result().key(forSlotID: "a"))
    }

    func testCompletesAfterLastSlot() {
        var s = ScanSession(slots: slots)
        s.record(keyCode: 1, character: "a")
        XCTAssertFalse(s.isComplete)
        s.record(keyCode: 2, character: "b")
        XCTAssertTrue(s.isComplete)
        XCTAssertNil(s.currentSlot)
    }

    func testRecordAfterCompleteIsNoOp() {
        var s = ScanSession(slots: slots)
        s.record(keyCode: 1, character: "a")
        s.record(keyCode: 2, character: "b")
        s.record(keyCode: 3, character: "c")
        XCTAssertEqual(s.result().keys.count, 2)
    }
}
