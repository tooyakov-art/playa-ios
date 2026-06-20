#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it first, then rerun this script."
  echo "CI installs it with: brew install xcodegen"
  exit 1
fi

DEVICE_NAME="${DEVICE_NAME:-Playa Screenshots 6.9}"
DEVICE_TYPE="${DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max}"
RUNTIME="${RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-5}"
DERIVED_DATA="$ROOT/build/DerivedDataScreenshots"
OUT_DIR="$ROOT/app-store/screenshots/raw"

mkdir -p "$OUT_DIR"

bash scripts/fetch-fonts.sh
xcodegen generate

SIM_ID="$(xcrun simctl list devices available | awk -v name="$DEVICE_NAME" '$0 ~ name { gsub(/[()]/, "", $2); print $2; exit }')"
if [[ -z "${SIM_ID:-}" ]]; then
  SIM_ID="$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME")"
fi

xcrun simctl boot "$SIM_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIM_ID" -b

xcodebuild build \
  -project Playa.xcodeproj \
  -scheme Playa \
  -configuration Debug \
  -destination "id=$SIM_ID" \
  -derivedDataPath "$DERIVED_DATA"

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Playa.app"
xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl launch "$SIM_ID" app.playahub

echo "App launched on simulator $SIM_ID."
echo "Navigate manually to each App Store screen, then run:"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/01-login.png"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/02-feed.png"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/03-categories.png"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/04-event-detail.png"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/05-chats.png"
echo "xcrun simctl io $SIM_ID screenshot app-store/screenshots/raw/06-profile.png"
