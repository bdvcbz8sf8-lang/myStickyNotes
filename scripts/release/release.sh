#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

NOTARIZE="${NOTARIZE:-0}"

"$ROOT_DIR/scripts/release/build_app.sh"
"$ROOT_DIR/scripts/release/package_dmg.sh"

if [[ "$NOTARIZE" == "1" ]]; then
  "$ROOT_DIR/scripts/release/notarize.sh"
else
  echo "Skipping notarization (NOTARIZE=0)."
  echo "Set NOTARIZE=1 and provide notary credentials to notarize."
fi
