#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="${APP_NAME:-StickyNotes}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-DesktopStickyNotes}"
BUNDLE_ID="${BUNDLE_ID:-com.example.desktopstickynotes}"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
ICON_PNG="${ICON_PNG:-$ROOT_DIR/icon.png}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build-release}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

APP_DIR="$OUT_DIR/$APP_NAME.app"
ICONSET_DIR="$OUT_DIR/AppIcon.iconset"
BIN_PATH_APPLE="$ROOT_DIR/.build/apple/Products/Release/$EXECUTABLE_NAME"
BIN_PATH_ARM="$ROOT_DIR/.build/arm64-apple-macosx/release/$EXECUTABLE_NAME"

echo "==> Building Swift package (release)"
cd "$ROOT_DIR"
swift build -c release

BIN_PATH="$BIN_PATH_APPLE"
if [[ ! -f "$BIN_PATH" ]]; then
  BIN_PATH="$BIN_PATH_ARM"
fi
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Release binary not found."
  exit 1
fi

if [[ ! -f "$ICON_PNG" ]]; then
  echo "Icon PNG not found: $ICON_PNG"
  exit 1
fi

echo "==> Preparing app bundle"
rm -rf "$APP_DIR" "$ICONSET_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$ICONSET_DIR"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Building AppIcon.icns from $ICON_PNG"
sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_PNG" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$OUT_DIR/AppIcon.icns"
cp "$OUT_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing app with identity: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
else
  echo "==> Signing app ad-hoc (local build)"
  codesign --force --deep --sign - "$APP_DIR"
fi

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo
echo "Built app:"
echo "  $APP_DIR"
