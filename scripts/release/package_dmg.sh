#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="${APP_NAME:-DesktopStickyNotes}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build-release}"
VOL_NAME="${VOL_NAME:-$APP_NAME}"
DMG_NAME="${DMG_NAME:-$APP_NAME.dmg}"

APP_DIR="$OUT_DIR/$APP_NAME.app"
STAGE_DIR="$OUT_DIR/dmg-stage"
DMG_PATH="$OUT_DIR/$DMG_NAME"

if [[ ! -d "$APP_DIR" ]]; then
  echo "App bundle not found: $APP_DIR"
  exit 1
fi

echo "==> Preparing DMG staging folder"
rm -rf "$STAGE_DIR" "$DMG_PATH"
mkdir -p "$STAGE_DIR"
cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

echo "==> Creating DMG: $DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo
echo "Built DMG:"
echo "  $DMG_PATH"
