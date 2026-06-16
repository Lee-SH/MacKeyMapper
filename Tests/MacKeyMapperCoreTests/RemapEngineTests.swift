import XCTest
@testable import MacKeyMapperCore

final class RemapEngineTests: XCTestCase {
    // leftControl=0x7000000E0=30064771296, rightControl=0x7000000E4=30064771300
    func testJSONForSingleMapping() {
        let m = [KeyMapping(sourceKeyID: "leftControl", destKeyID: "rightControl")]
        let json = RemapEngine.userKeyMappingJSON(for: m)
        XCTAssertEqual(json,
            "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":30064771296,\"HIDKeyboardModifierMappingDst\":30064771300}]}")
    }

    func testJSONForEmptyMappings() {
        XCTAssertEqual(RemapEngine.userKeyMappingJSON(for: []), "{\"UserKeyMapping\":[]}")
    }

    func testHidutilArguments() {
        let m = [KeyMapping(sourceKeyID: "capsLock", destKeyID: "leftControl")]
        let args = RemapEngine.hidutilArguments(for: m)
        XCTAssertEqual(args[0], "property")
        XCTAssertEqual(args[1], "--set")
        XCTAssertTrue(args[2].contains("UserKeyMapping"))
    }

    func testClearArguments() {
        XCTAssertEqual(RemapEngine.clearArguments(),
                       ["property", "--set", "{\"UserKeyMapping\":[]}"])
    }

    func testLaunchAgentPlistContainsEssentials() {
        let plist = RemapEngine.launchAgentPlist(arguments: ["property", "--set", "{\"UserKeyMapping\":[]}"])
        XCTAssertTrue(plist.contains("<string>com.mackeymapper.remap</string>"))
        XCTAssertTrue(plist.contains("<string>/usr/bin/hidutil</string>"))
        XCTAssertTrue(plist.contains("<key>RunAtLoad</key>"))
        XCTAssertTrue(plist.contains("<true/>"))
    }

    func testLaunchAgentPlistEscapesSpecialCharacters() {
        let plist = RemapEngine.launchAgentPlist(arguments: ["a&b", "c<d"])
        XCTAssertTrue(plist.contains("<string>a&amp;b</string>"))
        XCTAssertTrue(plist.contains("<string>c&lt;d</string>"))
    }

    func testLaunchAgentURLPath() {
        XCTAssertTrue(RemapEngine.launchAgentURL().path
            .hasSuffix("Library/LaunchAgents/com.mackeymapper.remap.plist"))
    }
}
