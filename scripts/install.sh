#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# 1) 릴리즈 .app 번들 빌드 (make-app.sh 재사용)
./scripts/make-app.sh

# 2) /Applications 로 설치
DEST="/Applications/MacKeyMapper.app"
echo "Installing to $DEST ..."
rm -rf "$DEST"
cp -R "build/MacKeyMapper.app" "$DEST"

# 3) 설치 위치에서 ad-hoc 재서명 (손쉬운 사용 권한이 이 경로/서명에 묶이도록)
codesign --force --deep --sign - "$DEST"

echo ""
echo "✅ 설치 완료: $DEST"
echo "   - Launchpad/응용 프로그램에서 'MacKeyMapper' 더블클릭, 또는: open -a MacKeyMapper"
echo "   - 첫 실행 시 '손쉬운 사용' 권한을 허용한 뒤 앱 내 '다시 확인'을 누르세요."
