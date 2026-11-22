#!/usr/bin/env bash
# Makes the iPhone project (ios/) and puts in the Rep Rival icon, splash and permission wording.
# Codemagic runs this on its Mac. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d ios ] || npx cap add ios
npx cap sync ios
P=ios/App/App/Info.plist
pb() { /usr/libexec/PlistBuddy -c "Delete :$1" "$P" 2>/dev/null || true; /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$P"; }
pb NSLocationWhenInUseUsageDescription string "Rep Rival uses your location only for features you turn on, like timing a run. It is never shared."
pb NSLocationAlwaysAndWhenInUseUsageDescription string "Rep Rival uses your location only for features you turn on, like timing a run. It is never shared."
pb NSMotionUsageDescription string "Rep Rival uses the motion sensors only for features you turn on."
pb NSCameraUsageDescription string "Rep Rival uses the camera only when you choose to add a photo or a video."
pb NSPhotoLibraryUsageDescription string "Rep Rival opens your photos only when you choose one to add."
pb NSMicrophoneUsageDescription string "Rep Rival listens only after you tap the mic, so you can say a command like Coach, start. Nothing you say is recorded or uploaded."
pb NSSpeechRecognitionUsageDescription string "Rep Rival turns what you say into words so it can press its buttons for you."
# RR30 · the coach's ears (same native files as Club Rival CR038): copy them in, add them to the project, point the main screen at them.
cp native/*.swift ios/App/App/
ruby -e "require 'xcodeproj'" 2>/dev/null || gem install xcodeproj --no-document --user-install
ruby native/add-native.rb || { GEM_HOME="$(ruby -e 'print Gem.user_dir')" ruby native/add-native.rb; }
SB=ios/App/App/Base.lproj/Main.storyboard
if grep -q 'customClass="CAPBridgeViewController"' "$SB"; then
  sed -i "" 's/customClass="CAPBridgeViewController" customModule="Capacitor"/customClass="RivalViewController" customModule="App" customModuleProvider="target"/' "$SB"
fi
grep -q 'customClass="RivalViewController"' "$SB" || { echo "RR30: could not point Main.storyboard at RivalViewController"; exit 1; }
# R2 · app link: Club Rival opens this app with rivalrep://open
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$P" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" -c "Add :CFBundleURLTypes:0 dict" -c "Add :CFBundleURLTypes:0:CFBundleURLName string rivalrep" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string rivalrep" "$P"
# R2 · the second, sturdier way to attach the ears (the list Capacitor itself reads), then checks that STOP the build if any piece is missing.
node -e "const fs=require('fs'),f='ios/App/App/capacitor.config.json';const j=JSON.parse(fs.readFileSync(f,'utf8'));j.packageClassList=[...new Set([...(j.packageClassList||[]),'CoachSpeechPlugin'])];fs.writeFileSync(f,JSON.stringify(j,null,2))"
grep -q '"CoachSpeechPlugin"' ios/App/App/capacitor.config.json || { echo "RR31: could not add CoachSpeechPlugin to capacitor.config.json"; exit 1; }
for F in CoachSpeechPlugin.swift RivalViewController.swift; do grep -q "$F in Sources" ios/App/App.xcodeproj/project.pbxproj || { echo "RR31: $F is not in the app project"; exit 1; }; done
grep -q "kit:'R3'" ios/App/App/RivalViewController.swift || { echo "RR31: old RivalViewController.swift - upload the whole zip again"; exit 1; }
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$P" | grep -qx "rivalrep" || { echo "RR31: app link rivalrep missing"; exit 1; }
echo "RR31: ears attached two ways, app link rivalrep:// ready"
pb ITSAppUsesNonExemptEncryption bool false
pb UIRequiresFullScreen bool true
# the icon: one 1024 picture, iOS makes every size from it
IC=$(find ios/App/App/Assets.xcassets/AppIcon.appiconset -name "*.png" | head -1)
cp assets/icon-1024.png "$IC"
# the launch screen: plain white, or plain black in dark mode; the Rep Rival start screen draws itself in right after.
SP=ios/App/App/Assets.xcassets/Splash.imageset; rm -f "$SP"/*.png; cp assets/splash-light.png "$SP/splash-light.png"; cp assets/splash-dark.png "$SP/splash-dark.png"; cp assets/splash-Contents.json "$SP/Contents.json"
# the build number goes up by one each Codemagic build
if [ -n "${BUILD_NUMBER:-}" ]; then sed -i "" -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" ios/App/App.xcodeproj/project.pbxproj; fi
echo "iPhone project ready: ${PWD}/ios"
