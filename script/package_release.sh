#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Vigil"
BUNDLE_NAME="Vigil"
BUNDLE_ID="dev.sumant.vigil"
VERSION="1.0.0"
BUILD_NUMBER="1"
MIN_SYSTEM_VERSION="13.0"
DEFAULT_IDENTITY="Developer ID Application: Sumant Subrahmanya (9J372EUGY8)"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$BUNDLE_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$BUNDLE_NAME-$VERSION-notarization.zip"
DMG_PATH="$DIST_DIR/$BUNDLE_NAME-$VERSION.dmg"
DMG_ROOT="$RELEASE_DIR/dmg-root"
IDENTITY="${CODESIGN_IDENTITY:-$DEFAULT_IDENTITY}"

cd "$ROOT_DIR"

"$ROOT_DIR/script/generate_icon.sh"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE" "$ZIP_PATH" "$DMG_PATH" "$DMG_ROOT"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$BUNDLE_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$BUNDLE_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 Sumant Subrahmanya. All rights reserved.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

plutil -lint "$INFO_PLIST"
codesign --force --timestamp --options runtime --sign "$IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -volname "$BUNDLE_NAME" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DMG_PATH"
echo "Signed app: $APP_BUNDLE"
echo "Notarization zip: $ZIP_PATH"
echo "DMG: $DMG_PATH"

if [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler staple "$DMG_PATH"
  spctl -a -vvv -t install "$APP_BUNDLE"
else
  echo "Skipping notarization: set NOTARYTOOL_PROFILE to a configured xcrun notarytool keychain profile."
fi
