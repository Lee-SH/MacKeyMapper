# MacKeyMapper 설계 문서

작성일: 2026-06-16

## 배경 / 문제

Mac Studio(macOS 15.5) 환경에서 Leopold(Windows 레이아웃) 외장 키보드를 사용 중.
Windows용 키 배치라 Mac에서 모디파이어(특히 Ctrl)가 의도대로 동작하지 않음
(예: 왼쪽 Ctrl 미입력, 오른쪽만 인식). Mac 전용 키보드처럼 동작하도록,
현재 키 입력값을 눈으로 확인하고 원하는 Mac 키 위치로 시스템 전체에서 리매핑하는
macOS 전용 앱을 만든다.

## 요구사항

1. 실행 시 Mac 키보드 레이아웃을 화면에 표시한다.
2. 물리 키 입력 시 해당 키가 레이아웃에서 하이라이트되어, 어떤 키값이 입력됐는지 확인할 수 있다.
3. 임의의 키를 원하는 Mac 키 위치로 리매핑하고, 그 설정이 **시스템 전체**(모든 앱)에
   적용되며 재부팅/로그인 후에도 유지된다.

## 핵심 기술 결정

- **스택:** Swift + SwiftUI 네이티브 macOS 앱. (전역 키 감지·전역 리매핑이 macOS API와
  강하게 결합되어 Java보다 네이티브가 압도적으로 적합. Xcode 16.1 / Swift 6 로컬 빌드.)
- **리매핑 수단:** macOS 내장 `hidutil property --set` (HID usage code 기반 key→key 매핑).
  좌/우 Ctrl·Opt·Cmd가 별도 HID 코드라 "왼쪽만 안 먹는" 문제를 정확히 다룸. sudo 불필요(per-user).
- **영속화:** `~/Library/LaunchAgents` 의 LaunchAgent plist가 로그인 시 hidutil을 재적용.
- **키보드 표현:** 정적 PNG가 아니라 **키 셀 단위로 그린 인터랙티브 레이아웃**.
  요구사항 2(개별 하이라이트)와 3(키 클릭으로 선택)이 키 단위 인터랙션을 요구하기 때문.
- **상호작용 특성:** hidutil 리매핑은 HID 레벨(CGEventTap보다 먼저)에서 일어나므로,
  리매핑 적용 후 물리 키를 누르면 시각화에는 **바뀐 결과** 키가 하이라이트됨
  → 설정이 제대로 먹었는지 검증하는 도구로 활용.

## 아키텍처 (컴포넌트 5개)

| 컴포넌트 | 역할 | 의존 |
|---|---|---|
| `KeyEventMonitor` | `CGEventTap`(리슨 전용)으로 실시간 키 입력 감지 (keyDown/keyUp + 좌/우 모디파이어 구분). `@Published` 로 현재 keyCode 방출 | 손쉬운 사용 권한 |
| `KeyboardView` | Mac 키보드 레이아웃을 키 셀 단위로 렌더. 눌린 키 하이라이트 + 클릭으로 리매핑 대상 선택 | `KeyCatalog` |
| `KeyCatalog` | 각 키의 `{라벨, 화면 위치(row/x/y/width), virtualKeyCode, HID usage code}` 매핑 테이블. 시각화(virtual keycode)와 리매핑(HID code)을 잇는 핵심 | — |
| `RemapEngine` | `hidutil property --set` 로 즉시 적용 + LaunchAgent plist 생성으로 영속화. 전체 초기화 지원 | hidutil |
| `RemapStore` | 사용자 매핑 설정을 JSON으로 저장/로드. UI·LaunchAgent의 단일 원본 | — |

## UI / UX

단일 창:
- 상단: 권한 상태 배너 (손쉬운 사용 미허용 시 "설정 열기" 버튼)
- 중앙: Mac 키보드 레이아웃 (그려진 키 셀들)
- 하단: 모드 토글 + 적용된 리매핑 목록(개별 삭제 가능) + "전체 초기화" 버튼

두 가지 모드:
1. **테스트 모드(기본):** 물리 키 → 레이아웃에서 하이라이트. 좌/우 구분 키는 각각 다른 위치에 표시.
2. **리매핑 모드:** 원본 키 클릭 → 대상 키 클릭 → 즉시 hidutil 적용 + 저장. 매핑은 그림 위 배지/화살표 + 하단 목록 표시.

레이아웃 범위: 표준 Mac ANSI, **TKL(텐키리스) + 모디파이어 행** 중심. 좌/우 Ctrl·Opt·Cmd 명확히 구분. 프로필 1개.

## 데이터 흐름

```
[실시간 감지]  물리 키 → CGEventTap → KeyEventMonitor → @Published keyCode → KeyboardView 하이라이트
[리매핑 설정]  원본키 클릭 → 대상키 클릭 → RemapStore(src.hid→dst.hid 저장)
              → RemapEngine: hidutil 즉시 적용 + LaunchAgent plist 재생성
[부팅/로그인]  LaunchAgent → hidutil 자동 재적용
```

저장 위치:
- 매핑 설정: `~/Library/Application Support/MacKeyMapper/mappings.json`
- 영속화: `~/Library/LaunchAgents/com.mackeymapper.remap.plist`

## 에러 처리

- 손쉬운 사용 권한 없음 → 배너 안내, 감지 기능만 비활성(리매핑은 계속 동작).
- hidutil 실행 실패 → 에러 메시지 + 종료 코드 표시.
- 잘못된 매핑(자기 자신으로 매핑 등) 검증·차단.

## 테스트

- 유닛: `KeyCatalog` 무결성(중복/누락 keycode 없음), `RemapEngine` hidutil JSON 생성,
  LaunchAgent plist 생성, `RemapStore` 직렬화/역직렬화.
- 수동: 이벤트탭 실제 감지, 실제 리매핑 적용(시스템 효과라 체크리스트로).

## 범위 밖 (YAGNI)

멀티 프로필, 매크로/조합키, 앱별 다른 매핑, 자동 업데이트.
