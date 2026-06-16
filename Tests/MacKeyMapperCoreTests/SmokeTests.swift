import XCTest
@testable import MacKeyMapperCore

final class SmokeTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(macKeyMapperCoreVersion, "0.0.1")
    }
}
