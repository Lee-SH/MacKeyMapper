#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# 1) Build the release .app bundle (reuse make-app.sh)
./scripts/make-app.sh

# 2) Install to /Applications
DEST="/Applications/MacKeyMapper.app"
echo "Installing to $DEST ..."
rm -rf "$DEST"
cp -R "build/MacKeyMapper.app" "$DEST"

# 3) Re-sign ad-hoc at the install location (so Input Monitoring permission binds to this path/signature)
codesign --force --deep --sign - "$DEST"

echo ""
echo "✅ Installed: $DEST"
echo "   - Double-click 'MacKeyMapper' in Launchpad/Applications, or run: open -a MacKeyMapper"
echo "   - On first launch, grant Input Monitoring permission, then click 'Re-check' in the app."
