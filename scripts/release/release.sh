#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="${APP_NAME:-StickyNotes}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-DesktopStickyNotes}"

NOTARIZE="${NOTARIZE:-0}"

APP_NAME="$APP_NAME" EXECUTABLE_NAME="$EXECUTABLE_NAME" "$ROOT_DIR/scripts/release/build_app.sh"
APP_NAME="$APP_NAME" "$ROOT_DIR/scripts/release/package_dmg.sh"

if [[ "$NOTARIZE" == "1" ]]; then
  APP_NAME="$APP_NAME" "$ROOT_DIR/scripts/release/notarize.sh"
else
  echo "Skipping notarization (NOTARIZE=0)."
  echo "Set NOTARIZE=1 and provide notary credentials to notarize."
fi
