import XCTest
@testable import MacKeyMapperCore

final class ScanTemplateTests: XCTestCase {
    func testRows0to4MatchMacCatalogCount() {
        let templateUpper = ScanTemplate.slots.filter { $0.row < 5 }.count
        let macUpper = KeyCatalog.keys.filter { $0.row < 5 }.count
        XCTAssertEqual(templateUpper, macUpper)
    }

    func testIncludesPCOnlyKeys() {
        let ids = Set(ScanTemplate.slots.map(\.id))
        XCTAssertTrue(ids.contains("hanyeong"))
        XCTAssertTrue(ids.contains("hanja"))
        XCTAssertTrue(ids.contains("menu"))
        XCTAssertTrue(ids.contains("escape"))
    }

    func testSlotIDsAreUnique() {
        let ids = ScanTemplate.slots.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
