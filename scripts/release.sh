#!/usr/bin/env bash
#
# Voicy release pipeline — archive → (codesign) → DMG → (notarize) → appcast.
#
# Designed to run in two modes:
#   * Without a paid Apple Developer account: archives with the local Personal
#     team, builds an UNSIGNED/locally-signed DMG, and generates an EdDSA-signed
#     appcast.xml. Good for testing the whole Sparkle flow today.
#   * With a paid account: set DEVELOPER_ID and NOTARY_PROFILE (see docs/RELEASE.md)
#     to additionally Developer-ID-sign, notarize, and staple the DMG.
#
# Sparkle's EdDSA signing reads the private key from the login keychain (created
# once via `bin/generate_keys`). The matching public key lives in the app's
# SUPublicEDKey Info.plist setting.
#
set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
SCHEME="Voicy"
CONFIGURATION="Release"
APP_NAME="Voicy"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/$APP_NAME.xcarchive"
RELEASE_DIR="$ROOT/release"        # holds the DMG(s) + generated appcast.xml
APP_PATH="$ARCHIVE/Products/Applications/$APP_NAME.app"

# Optional, account-gated:
DEVELOPER_ID="${DEVELOPER_ID:-}"           # e.g. "Developer ID Application: Name (TEAMID)"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"       # notarytool --keychain-profile name
# Path to Sparkle's generate_appcast (overridable). Auto-located if empty.
SPARKLE_BIN="${SPARKLE_BIN:-}"

mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

# ── 1. Archive ────────────────────────────────────────────────────────────────
echo "▸ Archiving $SCHEME ($CONFIGURATION)…"
archive_args=(
    -project "$ROOT/Voicy.xcodeproj"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -archivePath "$ARCHIVE"
    -destination "generic/platform=macOS"
)
# Pretty-print with xcbeautify when available; pipefail keeps build failures fatal.
if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild archive "${archive_args[@]}" | xcbeautify
else
    xcodebuild archive "${archive_args[@]}"
fi

[ -d "$APP_PATH" ] || { echo "✗ Archive produced no app at $APP_PATH"; exit 1; }
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
echo "▸ Built $APP_NAME $VERSION"

# ── 1b. Upload dSYMs to Sentry (config-gated) ────────────────────────────────
# Symbolicates production crash reports. Needs `sentry-cli` (brew install
# getsentry/tools/sentry-cli) and a `.sentryclirc` at the repo root with an
# auth token + org/project (see .sentryclirc.example). Both gitignored/optional,
# so a build without them just skips this — same pattern as signing/notarizing.
DSYM_DIR="$ARCHIVE/dSYMs"
if command -v sentry-cli >/dev/null 2>&1 && [ -f "$ROOT/.sentryclirc" ] && [ -d "$DSYM_DIR" ]; then
    echo "▸ Uploading dSYMs to Sentry…"
    ( cd "$ROOT" && sentry-cli debug-files upload "$DSYM_DIR" )
else
    echo "⚠︎ Skipping Sentry dSYM upload (need sentry-cli + .sentryclirc + dSYMs)."
fi

# ── 2. Developer ID signing (account-gated) ──────────────────────────────────
if [ -n "$DEVELOPER_ID" ]; then
    echo "▸ Developer-ID signing with hardened runtime…"
    codesign --deep --force --options runtime --timestamp \
        --sign "$DEVELOPER_ID" "$APP_PATH"
    codesign --verify --strict --verbose=2 "$APP_PATH"
else
    echo "⚠︎ DEVELOPER_ID not set — skipping Developer ID signing (DMG will not be notarizable)."
fi

# ── 3. DMG ────────────────────────────────────────────────────────────────────
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"
echo "▸ Building DMG → $DMG_PATH"
rm -f "$DMG_PATH"
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "$APP_NAME" \
        --app-drop-link 480 170 \
        --icon "$APP_NAME.app" 160 170 \
        --window-size 640 360 \
        "$DMG_PATH" "$APP_PATH" || hdiutil create -volname "$APP_NAME" \
            -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
else
    echo "⚠︎ create-dmg not found — falling back to hdiutil (no styling)."
    hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
fi

# ── 4. Notarize + staple (account-gated) ─────────────────────────────────────
if [ -n "$NOTARY_PROFILE" ]; then
    echo "▸ Notarizing (waiting for Apple)…"
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
    echo "▸ Gatekeeper assessment:"
    spctl -a -t open --context context:primary-signature -vv "$DMG_PATH" || true
else
    echo "⚠︎ NOTARY_PROFILE not set — skipping notarization/stapling."
fi

# ── 5. Sign + generate appcast (EdDSA, no Apple account needed) ───────────────
if [ -z "$SPARKLE_BIN" ]; then
    SPARKLE_BIN="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
        -path '*/artifacts/sparkle/Sparkle/bin/generate_appcast' 2>/dev/null | head -n1)"
fi
if [ -z "$SPARKLE_BIN" ] || [ ! -x "$SPARKLE_BIN" ]; then
    echo "✗ Sparkle's generate_appcast not found. Build once in Xcode to resolve the"
    echo "  package, or set SPARKLE_BIN to its path. See docs/RELEASE.md."
    exit 1
fi

echo "▸ Generating EdDSA-signed appcast…"
"$SPARKLE_BIN" "$RELEASE_DIR" \
    --download-url-prefix "https://github.com/adri567/voicy/releases/download/v$VERSION/"
cp "$RELEASE_DIR/appcast.xml" "$ROOT/appcast.xml"

echo "✓ Done. Artifacts in $RELEASE_DIR; appcast.xml copied to repo root."
echo "  Next: upload $DMG_PATH to the GitHub release tagged v$VERSION and deploy"
echo "  appcast.xml to https://voicy.pro/appcast.xml (see docs/RELEASE.md)."
