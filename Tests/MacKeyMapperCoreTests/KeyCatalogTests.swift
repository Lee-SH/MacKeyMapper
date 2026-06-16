import XCTest
@testable import MacKeyMapperCore

final class KeyCatalogTests: XCTestCase {
    func testNonEmpty() {
        XCTAssertGreaterThan(KeyCatalog.keys.count, 50)
    }

    func testIDsUnique() {
        let ids = KeyCatalog.keys.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "중복 id 존재")
    }

    func testVirtualKeyCodesUnique() {
        let vks = KeyCatalog.keys.map(\.virtualKeyCode)
        XCTAssertEqual(vks.count, Set(vks).count, "중복 virtualKeyCode 존재")
    }

    func testHIDUsagesUnique() {
        let hids = KeyCatalog.keys.map(\.hidUsage)
        XCTAssertEqual(hids.count, Set(hids).count, "중복 hidUsage 존재")
    }

    func testAllHIDUsagesInKeyboardPage() {
        for k in KeyCatalog.keys {
            XCTAssertGreaterThanOrEqual(k.hidUsage, 0x700000000, "\(k.id) hidUsage 범위 오류")
            XCTAssertLessThan(k.hidUsage, 0x700000100, "\(k.id) hidUsage 범위 오류")
        }
    }

    func testLookups() {
        XCTAssertEqual(KeyCatalog.key(id: "leftControl")?.virtualKeyCode, 59)
        XCTAssertEqual(KeyCatalog.key(forVirtualKeyCode: 62)?.id, "rightControl")
    }

    func testLeftRightModifiersDistinct() {
        let lc = KeyCatalog.key(id: "leftControl")
        let rc = KeyCatalog.key(id: "rightControl")
        XCTAssertNotEqual(lc?.virtualKeyCode, rc?.virtualKeyCode)
        XCTAssertNotEqual(lc?.hidUsage, rc?.hidUsage)
    }
}
