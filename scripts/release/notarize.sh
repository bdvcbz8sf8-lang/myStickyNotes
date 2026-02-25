#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="${APP_NAME:-StickyNotes}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build-release}"
DMG_NAME="${DMG_NAME:-$APP_NAME.dmg}"
APP_DIR="$OUT_DIR/$APP_NAME.app"
DMG_PATH="$OUT_DIR/$DMG_NAME"

if [[ ! -d "$APP_DIR" ]]; then
  echo "App bundle not found: $APP_DIR"
  exit 1
fi
if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found: $DMG_PATH"
  exit 1
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "==> Submitting DMG with notary profile: $NOTARY_PROFILE"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
else
  if [[ -z "${APPLE_ID:-}" || -z "${APPLE_APP_PASSWORD:-}" || -z "${APPLE_TEAM_ID:-}" ]]; then
    echo "Provide NOTARY_PROFILE, or APPLE_ID + APPLE_APP_PASSWORD + APPLE_TEAM_ID."
    exit 1
  fi
  echo "==> Submitting DMG with Apple ID credentials"
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait
fi

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_DIR"
xcrun stapler staple "$DMG_PATH"

echo
echo "Notarization complete."
