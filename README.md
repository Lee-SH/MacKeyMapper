# MacKeyMapper

macOS 전용 키보드 시각화 + 시스템 전역 리매핑 도구.

## 빌드/실행
- 개발: `swift run MacKeyMapper`
- 테스트: `swift test`
- 배포 번들: `./scripts/make-app.sh` → `build/MacKeyMapper.app`

## 권한
키 입력 감지에 '손쉬운 사용(Accessibility)' 권한 필요. 첫 실행 시 안내 배너에서 설정.

## 동작
- 테스트 모드: 누른 키가 레이아웃에 하이라이트 (좌/우 모디파이어 구분).
- 리매핑 모드: 원본 키 → 대상 키 클릭으로 매핑. `hidutil` 즉시 적용 + LaunchAgent로 로그인 시 유지.
- 전체 초기화: 모든 매핑 해제 및 LaunchAgent 제거.

## 저장 위치
- 매핑: `~/Library/Application Support/MacKeyMapper/mappings.json`
- 영속화: `~/Library/LaunchAgents/com.mackeymapper.remap.plist`
