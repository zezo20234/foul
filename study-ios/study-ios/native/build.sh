#!/usr/bin/env bash
# Builds an UNSIGNED StudyTogether.ipa. Run from the study-ios folder (the GitHub workflow does this).
set -euxo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

cd "$(dirname "$0")/.."          # -> study-ios
ROOT="$PWD"
BUILD_NO="${GITHUB_RUN_NUMBER:-1}"

echo "== node deps"
npm install --no-audit --no-fund

echo "== create iOS project"
rm -rf ios build Payload StudyTogether.ipa
npx cap add ios

APP=ios/App/App

echo "== app icon (from www/icon-512.png)"
ICON_DIR=$(find "$APP/Assets.xcassets" -type d -name 'AppIcon.appiconset' | head -1)
if [ -n "$ICON_DIR" ] && [ -f www/icon-512.png ]; then
  for f in "$ICON_DIR"/*.png; do
    [ -e "$f" ] && sips -z 1024 1024 www/icon-512.png --out "$f" >/dev/null
  done
fi

echo "== Info.plist"
PL="$APP/Info.plist"
PB=/usr/libexec/PlistBuddy
$PB -c "Delete :UIBackgroundModes" "$PL" 2>/dev/null || true
$PB -c "Add :UIBackgroundModes array" "$PL"
$PB -c "Add :UIBackgroundModes:0 string audio" "$PL"
$PB -c "Set :CFBundleDisplayName Study Together" "$PL" 2>/dev/null || $PB -c "Add :CFBundleDisplayName string Study Together" "$PL"

echo "== native files"
FILES=(alarm.wav)
cp native/alarm.wav "$APP/alarm.wav"
if [ -f native/enable-screentime ]; then
  echo "Screen Time blocking ENABLED (needs paid Apple account + Family Controls entitlement to actually run)"
  cp native/optional-screentime/ScreenTimePlugin.swift native/optional-screentime/ViewController.swift native/optional-screentime/App.entitlements "$APP/"
  sed -i '' 's/customClass="CAPBridgeViewController" customModule="Capacitor"/customClass="ViewController" customModule="App"/' "$APP/Base.lproj/Main.storyboard"
  grep -q 'customClass="ViewController"' "$APP/Base.lproj/Main.storyboard"
  FILES+=(ScreenTimePlugin.swift ViewController.swift App.entitlements)
fi
ruby native/add_files.rb "${FILES[@]}"

echo "== sync web files + pods"
npx cap sync ios

echo "== xcodebuild (unsigned)"
xcodebuild \
  -workspace ios/App/App.xcworkspace \
  -scheme App \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  MARKETING_VERSION=1.0 \
  CURRENT_PROJECT_VERSION="$BUILD_NO" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build

APP_PATH=$(find build/Build/Products -maxdepth 2 -name 'App.app' -type d | head -1)
test -d "$APP_PATH"

echo "== package IPA"
mkdir Payload
cp -R "$APP_PATH" Payload/
zip -qry StudyTogether.ipa Payload
rm -rf Payload
ls -la StudyTogether.ipa
