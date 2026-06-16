# MacKeyMapper

macOS 전용 키보드 시각화 + 시스템 전역 리매핑 도구.

## 빌드/실행
- 테스트: `swift test`
- 배포 번들(권장 실행 경로): `./scripts/make-app.sh` → `open build/MacKeyMapper.app`
- 개발용 빠른 컴파일 확인: `swift run MacKeyMapper`

> 키 입력 감지(이벤트탭)는 '손쉬운 사용' 권한이 **코드사인된 앱 번들**에 안정적으로 묶입니다.
> 따라서 실제 사용·테스트는 `swift run` 이 아니라 `make-app.sh` 로 만든 `.app` 실행을 권장합니다.
> (`swift run` 으로 띄운 임시 바이너리는 권한이 잘 유지되지 않아 하이라이트가 동작하지 않을 수 있음)

## 권한
키 입력 감지에 '손쉬운 사용(Accessibility)' 권한 필요. 첫 실행 시 안내 배너에서 '설정 열기'로
허용한 뒤 '다시 확인'을 누르면 즉시 감지가 켜집니다. (권한이 잡히지 않으면 앱을 다시 실행하세요.)

## 동작
- 테스트 모드: 누른 키가 레이아웃에 하이라이트 (좌/우 모디파이어 구분).
- 리매핑 모드: 원본 키 → 대상 키 클릭으로 매핑. `hidutil` 즉시 적용 + LaunchAgent로 로그인 시 유지.
- 전체 초기화: 모든 매핑 해제 및 LaunchAgent 제거.

## 저장 위치
- 매핑: `~/Library/Application Support/MacKeyMapper/mappings.json`
- 영속화: `~/Library/LaunchAgents/com.mackeymapper.remap.plist`
