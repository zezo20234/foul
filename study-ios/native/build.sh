#!/bin/bash
# Builds an unsigned StudyTogether.ipa. Run from the folder that contains www/ and native/.
set -euo pipefail

# use the newest Xcode installed on the runner (AlarmKit needs the iOS 26+ SDK)
XC=$(ls -d /Applications/Xcode*.app | sort -V | tail -1)
sudo xcode-select -s "$XC/Contents/Developer"
xcodebuild -version

npm install
npx cap add ios
sips -z 1024 1024 www/icon-512.png --out ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png || true
npx cap sync ios

# native code, alarm sound, Live Activity widget
cp native/ViewController.swift native/LiveActivityPlugin.swift native/StudyAttributes.swift native/StudyIntents.swift native/AlarmBridge.swift native/alarm.wav ios/App/App/
mkdir -p ios/App/StudyWidget
cp native/StudyWidget.swift native/StudyAttributes.swift native/StudyIntents.swift ios/App/StudyWidget/
cp native/StudyWidget-Info.plist ios/App/StudyWidget/Info.plist
ruby -e 'require "xcodeproj"' 2>/dev/null || sudo gem install xcodeproj --no-document
ruby native/setup_xcode.rb

# Info.plist: Live Activities + background audio
PB=/usr/libexec/PlistBuddy
PL=ios/App/App/Info.plist
$PB -c "Add :NSSupportsLiveActivities bool true" "$PL" || true
$PB -c "Add :UIBackgroundModes array" "$PL" || true
$PB -c "Add :UIBackgroundModes:0 string audio" "$PL" || true
$PB -c "Add :NSAlarmKitUsageDescription string Rings an alarm when your study timer ends." "$PL" || true

# use our ViewController (registers the Live Activity plugin)
SB=ios/App/App/Base.lproj/Main.storyboard
sed -i '' -E 's/customClass="CAPBridgeViewController"( customModule="Capacitor")?/customClass="ViewController" customModule="App"/' "$SB"
grep -q 'customClass="ViewController"' "$SB" || { echo "Storyboard was not patched:"; grep -n customClass "$SB"; exit 1; }

build() {
  xcodebuild \
    -workspace ios/App/App.xcworkspace \
    -scheme App \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build
}
if ! build; then
  echo "=== AlarmKit DISABLED: first build failed, retrying without system alarms ==="
  cp native/AlarmBridgeStub.swift ios/App/App/AlarmBridge.swift
  build
  echo "=== AlarmKit DISABLED: built without system alarms (notification alarm is used instead) ==="
fi

rm -rf Payload StudyTogether.ipa
mkdir Payload
cp -R build/Build/Products/Release-iphoneos/App.app Payload/
zip -qr StudyTogether.ipa Payload
echo "Built StudyTogether.ipa"
