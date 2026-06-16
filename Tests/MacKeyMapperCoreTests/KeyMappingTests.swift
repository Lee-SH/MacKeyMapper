import XCTest
@testable import MacKeyMapperCore

final class KeyMappingTests: XCTestCase {
    private let catalog = [
        KeyDefinition(id: "a", label: "A", virtualKeyCode: 0, hidUsage: 0x700000004, row: 3),
        KeyDefinition(id: "b", label: "B", virtualKeyCode: 11, hidUsage: 0x700000005, row: 4),
        KeyDefinition(id: "c", label: "C", virtualKeyCode: 8, hidUsage: 0x700000006, row: 4),
    ]

    func testValidMappingsPass() throws {
        let m = [KeyMapping(sourceKeyID: "a", destKeyID: "b")]
        XCTAssertNoThrow(try validateMappings(m, catalog: catalog))
    }

    func testSelfMappingThrows() {
        let m = [KeyMapping(sourceKeyID: "a", destKeyID: "a")]
        XCTAssertThrowsError(try validateMappings(m, catalog: catalog)) { error in
            XCTAssertEqual(error as? MappingError, .selfMapping(keyID: "a"))
        }
    }

    func testDuplicateSourceThrows() {
        let m = [KeyMapping(sourceKeyID: "a", destKeyID: "b"),
                 KeyMapping(sourceKeyID: "a", destKeyID: "c")]
        XCTAssertThrowsError(try validateMappings(m, catalog: catalog)) { error in
            XCTAssertEqual(error as? MappingError, .duplicateSource(keyID: "a"))
        }
    }

    func testUnknownKeyThrows() {
        let m = [KeyMapping(sourceKeyID: "a", destKeyID: "z")]
        XCTAssertThrowsError(try validateMappings(m, catalog: catalog)) { error in
            XCTAssertEqual(error as? MappingError, .unknownKey(keyID: "z"))
        }
    }

    func testMappingIDIsStable() {
        XCTAssertEqual(KeyMapping(sourceKeyID: "a", destKeyID: "b").id, "a->b")
    }
}
