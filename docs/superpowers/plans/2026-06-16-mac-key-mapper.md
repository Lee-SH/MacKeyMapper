# MacKeyMapper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS 전용 앱으로, 물리 키 입력을 Mac 키보드 레이아웃에 실시간 하이라이트하고, 임의의 키를 원하는 Mac 키로 시스템 전체에서 리매핑(재부팅 후에도 유지)한다.

**Architecture:** Swift Package Manager 프로젝트. 순수 로직(키 카탈로그·리매핑 엔진·저장소)은 `MacKeyMapperCore` 라이브러리에 모아 `swift test`로 전부 단위 테스트한다. UI(SwiftUI)와 전역 키 감지(`CGEventTap`)는 `MacKeyMapper` 실행 타깃에 두고 Core에 의존한다. 리매핑은 macOS 내장 `hidutil` 로 즉시 적용하고, `~/Library/LaunchAgents` plist로 로그인 시 재적용해 영속화한다.

**Tech Stack:** Swift 6, SwiftUI, CoreGraphics(CGEventTap), ApplicationServices(AXIsProcessTrusted), Foundation(Process/JSON), hidutil, launchd.

---

## File Structure

```
MacKeyMapper/
  Package.swift
  Sources/
    MacKeyMapperCore/
      KeyDefinition.swift      # 키 모델 (라벨/virtualKeyCode/hidUsage/row/width)
      KeyMapping.swift         # src→dst 매핑 모델 + 검증
      KeyCatalog.swift         # 전체 키 테이블 + 조회
      RemapEngine.swift        # hidutil JSON/인자/plist 생성 + 적용/설치/초기화
      RemapStore.swift         # mappings.json 저장/로드
    MacKeyMapper/
      MacKeyMapperApp.swift    # @main App
      AppState.swift           # ObservableObject (전체 상태/액션)
      KeyEventMonitor.swift    # CGEventTap 전역 감지
      Permissions.swift        # 손쉬운 사용 권한 확인/요청
      Views/
        ContentView.swift
        KeyboardView.swift
        KeyCapView.swift
        MappingListView.swift
        PermissionBanner.swift
  Tests/
    MacKeyMapperCoreTests/
      KeyMappingTests.swift
      KeyCatalogTests.swift
      RemapEngineTests.swift
      RemapStoreTests.swift
  scripts/
    make-app.sh                # .app 번들 패키징
```

각 파일은 단일 책임을 가진다. Core는 프레임워크 의존 없는 순수 Swift(Foundation만)라 헤드리스 테스트가 가능하다.

---

## Task 1: SPM 프로젝트 스캐폴드

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacKeyMapperCore/Placeholder.swift` (임시)
- Create: `Tests/MacKeyMapperCoreTests/SmokeTests.swift`

- [ ] **Step 1: `Package.swift` 작성**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacKeyMapper",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MacKeyMapperCore"),
        .executableTarget(
            name: "MacKeyMapper",
            dependencies: ["MacKeyMapperCore"]
        ),
        .testTarget(
            name: "MacKeyMapperCoreTests",
            dependencies: ["MacKeyMapperCore"]
        ),
    ]
)
```

- [ ] **Step 2: 임시 소스/테스트 작성 (빌드 통과용)**

`Sources/MacKeyMapperCore/Placeholder.swift`:
```swift
public let macKeyMapperCoreVersion = "0.0.1"
```

`Tests/MacKeyMapperCoreTests/SmokeTests.swift`:
```swift
import XCTest
@testable import MacKeyMapperCore

final class SmokeTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(macKeyMapperCoreVersion, "0.0.1")
    }
}
```

- [ ] **Step 3: 빌드/테스트 통과 확인**

Run: `cd /Users/gwanlija/IdeaProjects/MacKeyMapper && swift test`
Expected: PASS (1 test). 실행 타깃은 main 없이도 executableTarget이 비어 빌드 실패할 수 있으니, 임시 `Sources/MacKeyMapper/main.swift` 에 `print("hi")` 를 두고 빌드 확인 후 Task 7에서 교체한다.

`Sources/MacKeyMapper/main.swift`:
```swift
print("MacKeyMapper placeholder")
```

Run: `swift build`
Expected: `Compiling ... Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "chore: scaffold SPM project"
```

---

## Task 2: 키 모델 + 매핑 검증

**Files:**
- Create: `Sources/MacKeyMapperCore/KeyDefinition.swift`
- Create: `Sources/MacKeyMapperCore/KeyMapping.swift`
- Test: `Tests/MacKeyMapperCoreTests/KeyMappingTests.swift`
- Delete: `Sources/MacKeyMapperCore/Placeholder.swift`, `Tests/MacKeyMapperCoreTests/SmokeTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

`Tests/MacKeyMapperCoreTests/KeyMappingTests.swift`:
```swift
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
```

- [ ] **Step 2: 테스트 실패 확인**

먼저 임시 파일 삭제:
```bash
rm Sources/MacKeyMapperCore/Placeholder.swift Tests/MacKeyMapperCoreTests/SmokeTests.swift
```
Run: `swift test`
Expected: FAIL — `KeyDefinition`/`KeyMapping`/`validateMappings` 미정의 컴파일 에러.

- [ ] **Step 3: 모델 구현**

`Sources/MacKeyMapperCore/KeyDefinition.swift`:
```swift
public struct KeyDefinition: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let virtualKeyCode: UInt16
    public let hidUsage: UInt64
    public let row: Int
    public let width: Double
    public let isModifier: Bool

    public init(id: String, label: String, virtualKeyCode: UInt16, hidUsage: UInt64,
                row: Int, width: Double = 1.0, isModifier: Bool = false) {
        self.id = id
        self.label = label
        self.virtualKeyCode = virtualKeyCode
        self.hidUsage = hidUsage
        self.row = row
        self.width = width
        self.isModifier = isModifier
    }
}
```

`Sources/MacKeyMapperCore/KeyMapping.swift`:
```swift
public struct KeyMapping: Codable, Equatable, Identifiable, Sendable {
    public let sourceKeyID: String
    public let destKeyID: String
    public var id: String { "\(sourceKeyID)->\(destKeyID)" }

    public init(sourceKeyID: String, destKeyID: String) {
        self.sourceKeyID = sourceKeyID
        self.destKeyID = destKeyID
    }
}

public enum MappingError: Error, Equatable {
    case selfMapping(keyID: String)
    case duplicateSource(keyID: String)
    case unknownKey(keyID: String)
}

public func validateMappings(_ mappings: [KeyMapping],
                             catalog: [KeyDefinition] = KeyCatalog.keys) throws {
    let ids = Set(catalog.map(\.id))
    var seenSources = Set<String>()
    for m in mappings {
        guard ids.contains(m.sourceKeyID) else { throw MappingError.unknownKey(keyID: m.sourceKeyID) }
        guard ids.contains(m.destKeyID) else { throw MappingError.unknownKey(keyID: m.destKeyID) }
        if m.sourceKeyID == m.destKeyID { throw MappingError.selfMapping(keyID: m.sourceKeyID) }
        if seenSources.contains(m.sourceKeyID) { throw MappingError.duplicateSource(keyID: m.sourceKeyID) }
        seenSources.insert(m.sourceKeyID)
    }
}
```

> 참고: `validateMappings` 의 기본 인자가 `KeyCatalog.keys` 를 참조하므로 Task 3까지는 컴파일되지 않는다. Task 3을 이어서 진행한 뒤 함께 테스트한다. (테스트는 catalog 인자를 직접 주입하므로 로직 자체는 독립적이다.)

- [ ] **Step 4: 임시로 빈 카탈로그 추가 후 테스트**

컴파일을 위해 Task 3 전에 임시 stub을 만든다:
`Sources/MacKeyMapperCore/KeyCatalog.swift`:
```swift
public enum KeyCatalog {
    public static let keys: [KeyDefinition] = []
}
```
Run: `swift test`
Expected: PASS (KeyMappingTests 5개).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add key model and mapping validation"
```

---

## Task 3: 키 카탈로그 테이블

**Files:**
- Modify: `Sources/MacKeyMapperCore/KeyCatalog.swift` (stub 교체)
- Test: `Tests/MacKeyMapperCoreTests/KeyCatalogTests.swift`

- [ ] **Step 1: 무결성 테스트 작성**

`Tests/MacKeyMapperCoreTests/KeyCatalogTests.swift`:
```swift
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
            XCTAssertLessThan(k.hidUsage, 0x7000000FF, "\(k.id) hidUsage 범위 오류")
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
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `swift test --filter KeyCatalogTests`
Expected: FAIL (stub은 빈 배열, lookup 메서드 없음).

- [ ] **Step 3: 카탈로그 구현 (stub 교체)**

`Sources/MacKeyMapperCore/KeyCatalog.swift` 전체 교체:
```swift
public enum KeyCatalog {
    // hidUsage = 0x700000000 | (USB HID Keyboard/Keypad usage)
    public static let keys: [KeyDefinition] = [
        // Row 0 — function row
        .init(id: "escape", label: "esc", virtualKeyCode: 53, hidUsage: 0x700000000 | 0x29, row: 0, width: 1.5),
        .init(id: "f1", label: "F1", virtualKeyCode: 122, hidUsage: 0x700000000 | 0x3A, row: 0),
        .init(id: "f2", label: "F2", virtualKeyCode: 120, hidUsage: 0x700000000 | 0x3B, row: 0),
        .init(id: "f3", label: "F3", virtualKeyCode: 99,  hidUsage: 0x700000000 | 0x3C, row: 0),
        .init(id: "f4", label: "F4", virtualKeyCode: 118, hidUsage: 0x700000000 | 0x3D, row: 0),
        .init(id: "f5", label: "F5", virtualKeyCode: 96,  hidUsage: 0x700000000 | 0x3E, row: 0),
        .init(id: "f6", label: "F6", virtualKeyCode: 97,  hidUsage: 0x700000000 | 0x3F, row: 0),
        .init(id: "f7", label: "F7", virtualKeyCode: 98,  hidUsage: 0x700000000 | 0x40, row: 0),
        .init(id: "f8", label: "F8", virtualKeyCode: 100, hidUsage: 0x700000000 | 0x41, row: 0),
        .init(id: "f9", label: "F9", virtualKeyCode: 101, hidUsage: 0x700000000 | 0x42, row: 0),
        .init(id: "f10", label: "F10", virtualKeyCode: 109, hidUsage: 0x700000000 | 0x43, row: 0),
        .init(id: "f11", label: "F11", virtualKeyCode: 103, hidUsage: 0x700000000 | 0x44, row: 0),
        .init(id: "f12", label: "F12", virtualKeyCode: 111, hidUsage: 0x700000000 | 0x45, row: 0),

        // Row 1 — number row
        .init(id: "grave", label: "`", virtualKeyCode: 50, hidUsage: 0x700000000 | 0x35, row: 1),
        .init(id: "n1", label: "1", virtualKeyCode: 18, hidUsage: 0x700000000 | 0x1E, row: 1),
        .init(id: "n2", label: "2", virtualKeyCode: 19, hidUsage: 0x700000000 | 0x1F, row: 1),
        .init(id: "n3", label: "3", virtualKeyCode: 20, hidUsage: 0x700000000 | 0x20, row: 1),
        .init(id: "n4", label: "4", virtualKeyCode: 21, hidUsage: 0x700000000 | 0x21, row: 1),
        .init(id: "n5", label: "5", virtualKeyCode: 23, hidUsage: 0x700000000 | 0x22, row: 1),
        .init(id: "n6", label: "6", virtualKeyCode: 22, hidUsage: 0x700000000 | 0x23, row: 1),
        .init(id: "n7", label: "7", virtualKeyCode: 26, hidUsage: 0x700000000 | 0x24, row: 1),
        .init(id: "n8", label: "8", virtualKeyCode: 28, hidUsage: 0x700000000 | 0x25, row: 1),
        .init(id: "n9", label: "9", virtualKeyCode: 25, hidUsage: 0x700000000 | 0x26, row: 1),
        .init(id: "n0", label: "0", virtualKeyCode: 29, hidUsage: 0x700000000 | 0x27, row: 1),
        .init(id: "minus", label: "-", virtualKeyCode: 27, hidUsage: 0x700000000 | 0x2D, row: 1),
        .init(id: "equal", label: "=", virtualKeyCode: 24, hidUsage: 0x700000000 | 0x2E, row: 1),
        .init(id: "delete", label: "⌫", virtualKeyCode: 51, hidUsage: 0x700000000 | 0x2A, row: 1, width: 2.0),

        // Row 2 — QWERTY
        .init(id: "tab", label: "⇥", virtualKeyCode: 48, hidUsage: 0x700000000 | 0x2B, row: 2, width: 1.5),
        .init(id: "q", label: "Q", virtualKeyCode: 12, hidUsage: 0x700000000 | 0x14, row: 2),
        .init(id: "w", label: "W", virtualKeyCode: 13, hidUsage: 0x700000000 | 0x1A, row: 2),
        .init(id: "e", label: "E", virtualKeyCode: 14, hidUsage: 0x700000000 | 0x08, row: 2),
        .init(id: "r", label: "R", virtualKeyCode: 15, hidUsage: 0x700000000 | 0x15, row: 2),
        .init(id: "t", label: "T", virtualKeyCode: 17, hidUsage: 0x700000000 | 0x17, row: 2),
        .init(id: "y", label: "Y", virtualKeyCode: 16, hidUsage: 0x700000000 | 0x1C, row: 2),
        .init(id: "u", label: "U", virtualKeyCode: 32, hidUsage: 0x700000000 | 0x18, row: 2),
        .init(id: "i", label: "I", virtualKeyCode: 34, hidUsage: 0x700000000 | 0x0C, row: 2),
        .init(id: "o", label: "O", virtualKeyCode: 31, hidUsage: 0x700000000 | 0x12, row: 2),
        .init(id: "p", label: "P", virtualKeyCode: 35, hidUsage: 0x700000000 | 0x13, row: 2),
        .init(id: "leftBracket", label: "[", virtualKeyCode: 33, hidUsage: 0x700000000 | 0x2F, row: 2),
        .init(id: "rightBracket", label: "]", virtualKeyCode: 30, hidUsage: 0x700000000 | 0x30, row: 2),
        .init(id: "backslash", label: "\\", virtualKeyCode: 42, hidUsage: 0x700000000 | 0x31, row: 2, width: 1.5),

        // Row 3 — home row
        .init(id: "capsLock", label: "⇪", virtualKeyCode: 57, hidUsage: 0x700000000 | 0x39, row: 3, width: 1.75, isModifier: true),
        .init(id: "a", label: "A", virtualKeyCode: 0, hidUsage: 0x700000000 | 0x04, row: 3),
        .init(id: "s", label: "S", virtualKeyCode: 1, hidUsage: 0x700000000 | 0x16, row: 3),
        .init(id: "d", label: "D", virtualKeyCode: 2, hidUsage: 0x700000000 | 0x07, row: 3),
        .init(id: "f", label: "F", virtualKeyCode: 3, hidUsage: 0x700000000 | 0x09, row: 3),
        .init(id: "g", label: "G", virtualKeyCode: 5, hidUsage: 0x700000000 | 0x0A, row: 3),
        .init(id: "h", label: "H", virtualKeyCode: 4, hidUsage: 0x700000000 | 0x0B, row: 3),
        .init(id: "j", label: "J", virtualKeyCode: 38, hidUsage: 0x700000000 | 0x0D, row: 3),
        .init(id: "k", label: "K", virtualKeyCode: 40, hidUsage: 0x700000000 | 0x0E, row: 3),
        .init(id: "l", label: "L", virtualKeyCode: 37, hidUsage: 0x700000000 | 0x0F, row: 3),
        .init(id: "semicolon", label: ";", virtualKeyCode: 41, hidUsage: 0x700000000 | 0x33, row: 3),
        .init(id: "quote", label: "'", virtualKeyCode: 39, hidUsage: 0x700000000 | 0x34, row: 3),
        .init(id: "return", label: "⏎", virtualKeyCode: 36, hidUsage: 0x700000000 | 0x28, row: 3, width: 2.25),

        // Row 4 — bottom letter row
        .init(id: "leftShift", label: "⇧", virtualKeyCode: 56, hidUsage: 0x700000000 | 0xE1, row: 4, width: 2.25, isModifier: true),
        .init(id: "z", label: "Z", virtualKeyCode: 6, hidUsage: 0x700000000 | 0x1D, row: 4),
        .init(id: "x", label: "X", virtualKeyCode: 7, hidUsage: 0x700000000 | 0x1B, row: 4),
        .init(id: "c", label: "C", virtualKeyCode: 8, hidUsage: 0x700000000 | 0x06, row: 4),
        .init(id: "v", label: "V", virtualKeyCode: 9, hidUsage: 0x700000000 | 0x19, row: 4),
        .init(id: "b", label: "B", virtualKeyCode: 11, hidUsage: 0x700000000 | 0x05, row: 4),
        .init(id: "n", label: "N", virtualKeyCode: 45, hidUsage: 0x700000000 | 0x11, row: 4),
        .init(id: "m", label: "M", virtualKeyCode: 46, hidUsage: 0x700000000 | 0x10, row: 4),
        .init(id: "comma", label: ",", virtualKeyCode: 43, hidUsage: 0x700000000 | 0x36, row: 4),
        .init(id: "period", label: ".", virtualKeyCode: 47, hidUsage: 0x700000000 | 0x37, row: 4),
        .init(id: "slash", label: "/", virtualKeyCode: 44, hidUsage: 0x700000000 | 0x38, row: 4),
        .init(id: "rightShift", label: "⇧", virtualKeyCode: 60, hidUsage: 0x700000000 | 0xE5, row: 4, width: 2.75, isModifier: true),

        // Row 5 — modifier row (좌/우 구분이 핵심)
        .init(id: "leftControl", label: "⌃", virtualKeyCode: 59, hidUsage: 0x700000000 | 0xE0, row: 5, width: 1.25, isModifier: true),
        .init(id: "leftOption", label: "⌥", virtualKeyCode: 58, hidUsage: 0x700000000 | 0xE2, row: 5, width: 1.25, isModifier: true),
        .init(id: "leftCommand", label: "⌘", virtualKeyCode: 55, hidUsage: 0x700000000 | 0xE3, row: 5, width: 1.25, isModifier: true),
        .init(id: "space", label: "space", virtualKeyCode: 49, hidUsage: 0x700000000 | 0x2C, row: 5, width: 6.25),
        .init(id: "rightCommand", label: "⌘", virtualKeyCode: 54, hidUsage: 0x700000000 | 0xE7, row: 5, width: 1.25, isModifier: true),
        .init(id: "rightOption", label: "⌥", virtualKeyCode: 61, hidUsage: 0x700000000 | 0xE6, row: 5, width: 1.25, isModifier: true),
        .init(id: "rightControl", label: "⌃", virtualKeyCode: 62, hidUsage: 0x700000000 | 0xE4, row: 5, width: 1.25, isModifier: true),
    ]

    public static func key(id: String) -> KeyDefinition? {
        keys.first { $0.id == id }
    }

    public static func key(forVirtualKeyCode vk: UInt16) -> KeyDefinition? {
        keys.first { $0.virtualKeyCode == vk }
    }
}
```

> 화살표/숫자패드는 의도적으로 제외(YAGNI). 같은 패턴으로 카탈로그에 추가하면 확장된다.

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`
Expected: PASS (KeyCatalogTests + KeyMappingTests 전부).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add full TKL key catalog with HID/virtual codes"
```

---

## Task 4: RemapEngine 순수 생성기 (JSON/인자/plist)

**Files:**
- Create: `Sources/MacKeyMapperCore/RemapEngine.swift`
- Test: `Tests/MacKeyMapperCoreTests/RemapEngineTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

`Tests/MacKeyMapperCoreTests/RemapEngineTests.swift`:
```swift
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
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `swift test --filter RemapEngineTests`
Expected: FAIL — `RemapEngine` 미정의.

- [ ] **Step 3: 순수 생성기 구현**

`Sources/MacKeyMapperCore/RemapEngine.swift`:
```swift
import Foundation

public enum RemapEngine {
    public static let launchAgentLabel = "com.mackeymapper.remap"

    /// hidutil `--set` 에 넘길 UserKeyMapping JSON 문자열.
    public static func userKeyMappingJSON(for mappings: [KeyMapping],
                                          catalog: [KeyDefinition] = KeyCatalog.keys) -> String {
        let lookup = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0.hidUsage) })
        let entries = mappings.compactMap { m -> String? in
            guard let src = lookup[m.sourceKeyID], let dst = lookup[m.destKeyID] else { return nil }
            return "{\"HIDKeyboardModifierMappingSrc\":\(src),\"HIDKeyboardModifierMappingDst\":\(dst)}"
        }
        return "{\"UserKeyMapping\":[\(entries.joined(separator: ","))]}"
    }

    public static func hidutilArguments(for mappings: [KeyMapping],
                                        catalog: [KeyDefinition] = KeyCatalog.keys) -> [String] {
        ["property", "--set", userKeyMappingJSON(for: mappings, catalog: catalog)]
    }

    public static func clearArguments() -> [String] {
        ["property", "--set", "{\"UserKeyMapping\":[]}"]
    }

    public static func launchAgentPlist(arguments: [String]) -> String {
        let argXML = (["/usr/bin/hidutil"] + arguments)
            .map { arg -> String in
                let escaped = arg
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                return "        <string>\(escaped)</string>"
            }
            .joined(separator: "\n")
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
        \(argXML)
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`
Expected: PASS (전체).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add RemapEngine JSON/args/plist generators"
```

---

## Task 5: RemapStore 저장/로드

**Files:**
- Create: `Sources/MacKeyMapperCore/RemapStore.swift`
- Test: `Tests/MacKeyMapperCoreTests/RemapStoreTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

`Tests/MacKeyMapperCoreTests/RemapStoreTests.swift`:
```swift
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
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `swift test --filter RemapStoreTests`
Expected: FAIL — `RemapStore` 미정의.

- [ ] **Step 3: 구현**

`Sources/MacKeyMapperCore/RemapStore.swift`:
```swift
import Foundation

public struct RemapStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("MacKeyMapper/mappings.json")
    }

    public func load() throws -> [KeyMapping] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([KeyMapping].self, from: data)
    }

    public func save(_ mappings: [KeyMapping]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(mappings)
        try data.write(to: fileURL, options: .atomic)
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`
Expected: PASS (전체).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add RemapStore JSON persistence"
```

---

## Task 6: RemapEngine 부수효과 (적용/설치/초기화)

**Files:**
- Modify: `Sources/MacKeyMapperCore/RemapEngine.swift`
- Test: `Tests/MacKeyMapperCoreTests/RemapEngineTests.swift` (launchAgentURL 검증 추가)

- [ ] **Step 1: launchAgentURL 테스트 추가**

`RemapEngineTests.swift` 에 메서드 추가:
```swift
    func testLaunchAgentURLPath() {
        XCTAssertTrue(RemapEngine.launchAgentURL().path
            .hasSuffix("Library/LaunchAgents/com.mackeymapper.remap.plist"))
    }
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `swift test --filter RemapEngineTests/testLaunchAgentURLPath`
Expected: FAIL — `launchAgentURL` 미정의.

- [ ] **Step 3: 부수효과 메서드 구현 (RemapEngine.swift 하단에 추가)**

```swift
public enum RemapRuntimeError: Error, Equatable {
    case hidutilFailed(status: Int32, message: String)
}

extension RemapEngine {
    @discardableResult
    static func runHidutil(_ arguments: [String]) throws -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        proc.arguments = arguments
        let errPipe = Pipe()
        proc.standardError = errPipe
        proc.standardOutput = Pipe()
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus != 0 {
            let msg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                             encoding: .utf8) ?? ""
            throw RemapRuntimeError.hidutilFailed(status: proc.terminationStatus, message: msg)
        }
        return proc.terminationStatus
    }

    public static func apply(_ mappings: [KeyMapping],
                             catalog: [KeyDefinition] = KeyCatalog.keys) throws {
        try runHidutil(hidutilArguments(for: mappings, catalog: catalog))
    }

    public static func clearAll() throws {
        try runHidutil(clearArguments())
    }

    public static func launchAgentURL() -> URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaunchAgents/\(launchAgentLabel).plist")
    }

    public static func installLaunchAgent(for mappings: [KeyMapping],
                                          catalog: [KeyDefinition] = KeyCatalog.keys) throws {
        let url = launchAgentURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let plist = launchAgentPlist(arguments: hidutilArguments(for: mappings, catalog: catalog))
        try plist.write(to: url, atomically: true, encoding: .utf8)
    }

    public static func removeLaunchAgent() throws {
        let url = launchAgentURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
```

- [ ] **Step 4: 단위 테스트 통과 확인**

Run: `swift test`
Expected: PASS (전체). (apply/clearAll 의 실제 hidutil 실행은 Task 11 수동 검증.)

- [ ] **Step 5: hidutil 동작 수동 스모크 (선택)**

Run: `hidutil property --set '{"UserKeyMapping":[]}' && echo OK`
Expected: `OK` (hidutil 사용 가능 확인. 빈 매핑이라 효과 없음.)

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add RemapEngine side effects (apply/install/clear)"
```

---

## Task 7: 앱 골격 (App + AppState + ContentView)

**Files:**
- Delete: `Sources/MacKeyMapper/main.swift`
- Create: `Sources/MacKeyMapper/MacKeyMapperApp.swift`
- Create: `Sources/MacKeyMapper/AppState.swift`
- Create: `Sources/MacKeyMapper/KeyEventMonitor.swift`
- Create: `Sources/MacKeyMapper/Permissions.swift`
- Create: `Sources/MacKeyMapper/Views/ContentView.swift`

> 이 Task부터는 UI/시스템 통합이라 `swift test` 대상이 아니며, `swift run` 빌드 성공 + 수동 체크리스트로 검증한다.

- [ ] **Step 1: 임시 main 제거**

```bash
rm Sources/MacKeyMapper/main.swift
```

- [ ] **Step 2: Permissions / KeyEventMonitor 작성**

`Sources/MacKeyMapper/Permissions.swift`:
```swift
import ApplicationServices
import AppKit

enum Permissions {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptAndOpenSettings() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

`Sources/MacKeyMapper/KeyEventMonitor.swift`:
```swift
import CoreGraphics
import Foundation

/// CGEventTap 으로 keyDown/keyUp/flagsChanged 를 리슨 전용으로 감지한다.
/// 콜백 시그니처: (virtualKeyCode, isDown, isModifier)
final class KeyEventMonitor {
    var onEvent: ((UInt16, Bool, Bool) -> Void)?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard tap == nil else { return }
        let mask = (1 << CGEventType.keyDown.rawValue)
                 | (1 << CGEventType.keyUp.rawValue)
                 | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
            let code = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            switch type {
            case .keyDown:      monitor.onEvent?(code, true, false)
            case .keyUp:        monitor.onEvent?(code, false, false)
            case .flagsChanged: monitor.onEvent?(code, false, true)
            default:            break
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}
```

- [ ] **Step 3: AppState 작성**

`Sources/MacKeyMapper/AppState.swift`:
```swift
import SwiftUI
import MacKeyMapperCore

enum AppMode {
    case test
    case remap
}

@MainActor
final class AppState: ObservableObject {
    @Published var mode: AppMode = .test
    @Published var pressedKeyCodes: Set<UInt16> = []
    @Published var mappings: [KeyMapping] = []
    @Published var pendingSourceID: String? = nil
    @Published var accessibilityTrusted: Bool = false
    @Published var lastError: String? = nil

    let catalog = KeyCatalog.keys
    private let store = RemapStore(fileURL: RemapStore.defaultURL())
    private let monitor = KeyEventMonitor()

    func start() {
        accessibilityTrusted = Permissions.isTrusted()
        mappings = (try? store.load()) ?? []
        monitor.onEvent = { [weak self] code, isDown, isModifier in
            Task { @MainActor in
                self?.handleKey(code: code, isDown: isDown, isModifier: isModifier)
            }
        }
        monitor.start()
    }

    func refreshPermission() {
        accessibilityTrusted = Permissions.isTrusted()
    }

    private func handleKey(code: UInt16, isDown: Bool, isModifier: Bool) {
        if isModifier {
            if pressedKeyCodes.contains(code) {
                pressedKeyCodes.remove(code)
            } else {
                pressedKeyCodes.insert(code)
            }
        } else if isDown {
            pressedKeyCodes.insert(code)
        } else {
            pressedKeyCodes.remove(code)
        }
    }

    func keyTapped(_ key: KeyDefinition) {
        guard mode == .remap else { return }
        if let src = pendingSourceID {
            if src == key.id {
                pendingSourceID = nil   // 같은 키 다시 눌러 취소
            } else {
                addMapping(sourceID: src, destID: key.id)
                pendingSourceID = nil
            }
        } else {
            pendingSourceID = key.id
        }
    }

    func mapping(forSourceID id: String) -> KeyMapping? {
        mappings.first { $0.sourceKeyID == id }
    }

    private func addMapping(sourceID: String, destID: String) {
        var next = mappings.filter { $0.sourceKeyID != sourceID }
        next.append(KeyMapping(sourceKeyID: sourceID, destKeyID: destID))
        applyAndSave(next)
    }

    func removeMapping(_ m: KeyMapping) {
        applyAndSave(mappings.filter { $0.id != m.id })
    }

    func clearAll() {
        do {
            try RemapEngine.clearAll()
            try RemapEngine.removeLaunchAgent()
            try store.save([])
            mappings = []
            lastError = nil
        } catch {
            lastError = "\(error)"
        }
    }

    private func applyAndSave(_ next: [KeyMapping]) {
        do {
            try validateMappings(next)
            try RemapEngine.apply(next)
            try RemapEngine.installLaunchAgent(for: next)
            try store.save(next)
            mappings = next
            lastError = nil
        } catch {
            lastError = "\(error)"
        }
    }
}
```

- [ ] **Step 4: App + 최소 ContentView 작성**

`Sources/MacKeyMapper/MacKeyMapperApp.swift`:
```swift
import SwiftUI

@main
struct MacKeyMapperApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup("MacKeyMapper") {
            ContentView()
                .environmentObject(state)
                .onAppear { state.start() }
                .frame(minWidth: 900, minHeight: 360)
        }
        .windowResizability(.contentSize)
    }
}
```

`Sources/MacKeyMapper/Views/ContentView.swift` (이 Task에서는 자리표시 최소 버전):
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            Text("MacKeyMapper")
                .font(.title2).bold()
            Text(state.accessibilityTrusted ? "권한 OK" : "손쉬운 사용 권한 필요")
            Text("모드: \(state.mode == .test ? "테스트" : "리매핑")")
        }
        .padding()
    }
}
```

- [ ] **Step 5: 빌드 & 실행 확인**

Run: `swift build`
Expected: `Build complete!`

Run: `swift run MacKeyMapper`
Expected: 창이 뜨고 "MacKeyMapper" 타이틀 + 권한 상태 텍스트가 보인다. (Ctrl+C 로 종료.)

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add app skeleton (App, AppState, event monitor, permissions)"
```

---

## Task 8: 권한 배너 + 실시간 감지 연동

**Files:**
- Create: `Sources/MacKeyMapper/Views/PermissionBanner.swift`
- Modify: `Sources/MacKeyMapper/Views/ContentView.swift`

- [ ] **Step 1: PermissionBanner 작성**

`Sources/MacKeyMapper/Views/PermissionBanner.swift`:
```swift
import SwiftUI

struct PermissionBanner: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("키 입력 감지에는 ‘손쉬운 사용’ 권한이 필요합니다. 허용 후 앱을 다시 실행하세요.")
                .font(.callout)
            Spacer()
            Button("설정 열기") { Permissions.promptAndOpenSettings() }
            Button("다시 확인") { state.refreshPermission() }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 2: ContentView 에 배너 + 디버그 표시 연결**

`Sources/MacKeyMapper/Views/ContentView.swift` 전체 교체:
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.accessibilityTrusted {
                PermissionBanner()
            }
            Text("눌린 키코드: \(state.pressedKeyCodes.sorted().map(String.init).joined(separator: ", "))")
                .font(.system(.body, design: .monospaced))
            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
    }
}
```

- [ ] **Step 3: 빌드 & 수동 검증**

Run: `swift run MacKeyMapper`

수동 체크리스트:
- [ ] 권한 미허용 시 노란 배너 표시, "설정 열기" 클릭 시 손쉬운 사용 설정 패널 열림
- [ ] 권한 허용 + 앱 재실행 후, 키보드를 누르면 "눌린 키코드"에 숫자가 실시간 표시
- [ ] **왼쪽 Ctrl 누르면 59, 오른쪽 Ctrl 누르면 62** 로 서로 다르게 표시됨 (좌/우 구분 검증)

> 권한이 dev 바이너리 경로에 묶이므로, 손쉬운 사용 목록에서 이전 항목 제거 후 새로 추가가 필요할 수 있다. 안정적 권한 유지는 Task 11의 `.app` 번들로 해결.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire live key detection and permission banner"
```

---

## Task 9: 키보드 레이아웃 렌더링 + 하이라이트

**Files:**
- Create: `Sources/MacKeyMapper/Views/KeyCapView.swift`
- Create: `Sources/MacKeyMapper/Views/KeyboardView.swift`
- Modify: `Sources/MacKeyMapper/Views/ContentView.swift`

- [ ] **Step 1: KeyCapView 작성**

`Sources/MacKeyMapper/Views/KeyCapView.swift`:
```swift
import SwiftUI
import MacKeyMapperCore

struct KeyCapView: View {
    let key: KeyDefinition
    let unit: CGFloat
    let isPressed: Bool
    let isPendingSource: Bool
    let mappedDestLabel: String?
    let onTap: () -> Void

    var body: some View {
        let w = unit * key.width
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(background)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(border, lineWidth: isPendingSource ? 2 : 1))
            VStack(spacing: 1) {
                Text(key.label).font(.system(size: 12, weight: .medium))
                if let dest = mappedDestLabel {
                    Text("→\(dest)").font(.system(size: 9)).foregroundStyle(.blue)
                }
            }
            .padding(2)
        }
        .frame(width: w, height: unit)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var background: Color {
        if isPressed { return .accentColor.opacity(0.6) }
        if mappedDestLabel != nil { return .blue.opacity(0.12) }
        return Color(white: 0.18)
    }

    private var border: Color {
        isPendingSource ? .orange : Color(white: 0.35)
    }
}
```

- [ ] **Step 2: KeyboardView 작성 (행별 누적 배치)**

`Sources/MacKeyMapper/Views/KeyboardView.swift`:
```swift
import SwiftUI
import MacKeyMapperCore

struct KeyboardView: View {
    @EnvironmentObject var state: AppState
    let unit: CGFloat = 46

    private var rows: [Int] {
        Array(Set(state.catalog.map(\.row))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(keys(in: row)) { key in
                        KeyCapView(
                            key: key,
                            unit: unit,
                            isPressed: state.pressedKeyCodes.contains(key.virtualKeyCode),
                            isPendingSource: state.pendingSourceID == key.id,
                            mappedDestLabel: destLabel(for: key),
                            onTap: { state.keyTapped(key) }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func keys(in row: Int) -> [KeyDefinition] {
        state.catalog.filter { $0.row == row }
    }

    private func destLabel(for key: KeyDefinition) -> String? {
        guard let m = state.mapping(forSourceID: key.id),
              let dest = KeyCatalog.key(id: m.destKeyID) else { return nil }
        return dest.label
    }
}
```

- [ ] **Step 3: ContentView 에 KeyboardView 삽입**

`Sources/MacKeyMapper/Views/ContentView.swift` 전체 교체:
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.accessibilityTrusted {
                PermissionBanner()
            }
            KeyboardView()
            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
    }
}
```

- [ ] **Step 4: 빌드 & 수동 검증**

Run: `swift run MacKeyMapper`

수동 체크리스트:
- [ ] TKL 키보드 레이아웃이 행별로 정렬되어 표시됨
- [ ] 키를 누르면 해당 키캡이 강조색으로 하이라이트되고 떼면 원복
- [ ] 좌/우 Ctrl·Shift·Cmd·Opt가 각각 다른 위치에서 하이라이트됨

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: render keyboard layout with live highlight"
```

---

## Task 10: 리매핑 모드 (클릭 매핑) + 매핑 목록

**Files:**
- Create: `Sources/MacKeyMapper/Views/MappingListView.swift`
- Modify: `Sources/MacKeyMapper/Views/ContentView.swift`

- [ ] **Step 1: MappingListView 작성**

`Sources/MacKeyMapper/Views/MappingListView.swift`:
```swift
import SwiftUI
import MacKeyMapperCore

struct MappingListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("적용된 리매핑 (\(state.mappings.count))").font(.headline)
                Spacer()
                Button("전체 초기화", role: .destructive) { state.clearAll() }
                    .disabled(state.mappings.isEmpty)
            }
            if state.mappings.isEmpty {
                Text("리매핑 모드에서 ‘원본 키 → 바꿀 키’ 순서로 클릭하세요.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(state.mappings) { m in
                    HStack {
                        Text("\(label(m.sourceKeyID)) → \(label(m.destKeyID))")
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            state.removeMapping(m)
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    private func label(_ id: String) -> String {
        KeyCatalog.key(id: id).map { "\($0.label)(\($0.id))" } ?? id
    }
}
```

- [ ] **Step 2: ContentView 에 모드 토글 + 목록 추가**

`Sources/MacKeyMapper/Views/ContentView.swift` 전체 교체:
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !state.accessibilityTrusted {
                PermissionBanner()
            }

            Picker("모드", selection: $state.mode) {
                Text("테스트").tag(AppMode.test)
                Text("리매핑").tag(AppMode.remap)
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            .onChange(of: state.mode) { _, _ in state.pendingSourceID = nil }

            if state.mode == .remap {
                Text(promptText)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            KeyboardView()
            MappingListView()

            if let err = state.lastError {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
    }

    private var promptText: String {
        if let src = state.pendingSourceID {
            return "‘\(src)’ 선택됨 — 바꿀 대상 키를 클릭하세요. (같은 키 재클릭 시 취소)"
        }
        return "원본 키를 클릭하세요."
    }
}
```

- [ ] **Step 3: 빌드 & 수동 검증 (실제 리매핑)**

Run: `swift run MacKeyMapper`

수동 체크리스트:
- [ ] 리매핑 모드 전환 후 원본 키 클릭 → 주황 테두리로 선택 표시
- [ ] 대상 키 클릭 → 키캡에 `→대상` 배지, 하단 목록에 항목 추가
- [ ] **실제 적용 검증:** 예) `capsLock → leftControl` 매핑 후, 다른 앱(텍스트 편집기)에서 Caps Lock을 누르면 Control처럼 동작
- [ ] 테스트 모드로 돌아가 매핑된 물리 키를 누르면 **대상 키** 위치가 하이라이트됨 (HID 레벨 적용 확인)
- [ ] 목록의 휴지통 버튼으로 개별 삭제 시 즉시 반영
- [ ] "전체 초기화" 시 모든 매핑 해제 + 원래 키 동작 복귀

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add remap mode click flow and mapping list"
```

---

## Task 11: .app 패키징 + 영속화 종단 검증

**Files:**
- Create: `scripts/make-app.sh`
- Create: `README.md`

- [ ] **Step 1: 번들 스크립트 작성**

`scripts/make-app.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
APP="build/MacKeyMapper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/MacKeyMapper" "$APP/Contents/MacOS/MacKeyMapper"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>MacKeyMapper</string>
    <key>CFBundleDisplayName</key><string>MacKeyMapper</string>
    <key>CFBundleIdentifier</key><string>com.mackeymapper.app</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>MacKeyMapper</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# 로컬 사용을 위한 ad-hoc 서명 (손쉬운 사용 권한 안정화)
codesign --force --deep --sign - "$APP"
echo "Built: $APP"
```

```bash
chmod +x scripts/make-app.sh
```

- [ ] **Step 2: 번들 빌드**

Run: `./scripts/make-app.sh`
Expected: `Built: build/MacKeyMapper.app`

- [ ] **Step 3: 앱 실행 & 권한 부여**

Run: `open build/MacKeyMapper.app`
- 손쉬운 사용에 `MacKeyMapper.app` 추가/허용 후 앱 재실행.

- [ ] **Step 4: 종단(end-to-end) 수동 검증**

체크리스트:
- [ ] `.app` 실행 시 키 입력 감지가 동작 (권한이 번들에 안정적으로 묶임)
- [ ] 매핑 1개 설정 (예: `capsLock → leftControl`)
- [ ] `~/Library/LaunchAgents/com.mackeymapper.remap.plist` 생성됨 확인: `ls ~/Library/LaunchAgents/com.mackeymapper.remap.plist`
- [ ] `~/Library/Application Support/MacKeyMapper/mappings.json` 생성됨 확인
- [ ] **로그아웃/재로그인(또는 재부팅) 후** 앱을 켜지 않아도 매핑이 유지됨 (LaunchAgent가 적용)
- [ ] "전체 초기화" 후 plist 제거됨 확인: `ls ~/Library/LaunchAgents/ | grep mackeymapper` → 없음

> 재로그인 검증 전, 즉시 적용 테스트로 LaunchAgent를 수동 로드해볼 수도 있다:
> `launchctl unload ~/Library/LaunchAgents/com.mackeymapper.remap.plist 2>/dev/null; launchctl load ~/Library/LaunchAgents/com.mackeymapper.remap.plist`

- [ ] **Step 5: README 작성**

`README.md`:
```markdown
# MacKeyMapper

macOS 전용 키보드 시각화 + 시스템 전역 리매핑 도구.

## 빌드/실행
- 개발: `swift run MacKeyMapper`
- 테스트: `swift test`
- 배포 번들: `./scripts/make-app.sh` → `build/MacKeyMapper.app`

## 권한
키 입력 감지에 ‘손쉬운 사용(Accessibility)’ 권한 필요. 첫 실행 시 안내 배너에서 설정.

## 동작
- 테스트 모드: 누른 키가 레이아웃에 하이라이트 (좌/우 모디파이어 구분).
- 리매핑 모드: 원본 키 → 대상 키 클릭으로 매핑. `hidutil` 즉시 적용 + LaunchAgent로 로그인 시 유지.
- 전체 초기화: 모든 매핑 해제 및 LaunchAgent 제거.

## 저장 위치
- 매핑: `~/Library/Application Support/MacKeyMapper/mappings.json`
- 영속화: `~/Library/LaunchAgents/com.mackeymapper.remap.plist`
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add .app packaging script and README"
```

---

## 완료 기준

- `swift test` 전부 통과 (KeyMapping/KeyCatalog/RemapEngine/RemapStore).
- 앱 실행 시 Mac 키보드 레이아웃 표시 (요구사항 1).
- 물리 키 입력 시 해당 키 하이라이트, 좌/우 모디파이어 구분 (요구사항 2).
- 임의 키를 임의 Mac 키로 리매핑, 시스템 전역 적용 + 재로그인 후 유지 (요구사항 3).
