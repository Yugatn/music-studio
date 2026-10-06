#!/usr/bin/env bash
# Build a runnable macOS app bundle from the Swift package.
# Requires: macOS 14+, Xcode / Swift 6 toolchain.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="MusicStudio"
BUILD_DIR="$ROOT/.build/release"
STAGE="$ROOT/dist"
APP_DIR="$STAGE/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "→ swift build -c release"
swift build -c release --product MusicStudio

BIN="$BUILD_DIR/MusicStudio"
if [[ ! -x "$BIN" ]]; then
  # SwiftPM may place the binary under a triple directory
  BIN="$(find "$ROOT/.build" -type f -name MusicStudio -path '*/release/*' | head -n 1)"
fi
if [[ -z "${BIN}" || ! -x "$BIN" ]]; then
  echo "error: MusicStudio binary not found after build" >&2
  exit 1
fi

echo "→ staging app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES"
cp "$BIN" "$MACOS_DIR/MusicStudio"
chmod +x "$MACOS_DIR/MusicStudio"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MusicStudio</string>
  <key>CFBundleIdentifier</key>
  <string>app.yugatn.musicstudio</string>
  <key>CFBundleName</key>
  <string>Music Studio</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.2.0</string>
  <key>CFBundleVersion</key>
  <string>2</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

# Zip for distribution
ZIP="$STAGE/${APP_NAME}-macOS.zip"
rm -f "$ZIP"
(
  cd "$STAGE"
  zip -r -q "$(basename "$ZIP")" "${APP_NAME}.app"
)

echo ""
echo "Built:"
echo "  $APP_DIR"
echo "  $ZIP"
echo ""
echo "Open:  open \"$APP_DIR\""
echo "AI:    in-app inspector → connect remote AI (API URL + key)"
