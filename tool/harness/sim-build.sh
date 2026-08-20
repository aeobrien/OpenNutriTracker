#!/usr/bin/env bash
# Build the app for the iOS Simulator and install it, so a harness can drive it.
#
# Why this exists: the barcode scanner plugin cannot be built for an Apple
# Silicon simulator, so `flutter build ios --simulator` fails outright on this
# machine. That meant no screen in this app had ever been opened by anything but
# a person, which is how the 20 August walkthrough shipped with a home screen
# that had never been looked at. This swaps the scanner for a do-nothing
# stand-in for the length of the build and puts everything back afterwards.
#
# Usage:  tool/harness/sim-build.sh [simulator-udid]
#
# What goes on a phone is untouched: the swap lives in pubspec_overrides.yaml,
# which is git-ignored and deleted on the way out, including on failure.
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$PWD"
SIM="${1:-}"
BUNDLE="com.aeobrien.foodtracker"

# The session's own bin directory shadows Flutter's toolchain, so take it out.
export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v '^/Users/aidan/.claude/bin$' | paste -sd: -)"

restore() {
  rm -f "$ROOT/pubspec_overrides.yaml"
  ( cd "$ROOT" && flutter pub get >/dev/null 2>&1 ) || true
  echo "[sim-build] the real scanner is back in place"
}
trap restore EXIT

echo "[sim-build] standing the scanner down for the build"
cat > "$ROOT/pubspec_overrides.yaml" <<'YAML'
# Written by tool/harness/sim-build.sh and deleted again when it finishes.
dependency_overrides:
  mobile_scanner:
    path: tool/harness/mobile_scanner_stub
YAML

flutter pub get
( cd "$ROOT/ios" && pod install )
# Where the harness's throwaway kitchen computer is. Only a build made by this
# script carries an address; a phone build has none and behaves exactly as it
# always did. Override with MANTEL_BASE_URL=... in the environment.
MANTEL_URL="${MANTEL_BASE_URL:-http://127.0.0.1:8790}"
flutter build ios --simulator --debug --dart-define=MANTEL_BASE_URL="$MANTEL_URL"

APP="$ROOT/build/ios/iphonesimulator/Runner.app"
[ -d "$APP" ] || { echo "[sim-build] no Runner.app at $APP"; exit 1; }

if [ -z "$SIM" ]; then
  SIM="$(xcrun simctl list devices | awk '/Booted/ {print $NF}' | tr -d '()' | head -1)"
fi
[ -n "$SIM" ] || { echo "[sim-build] no simulator given and none booted"; exit 1; }

xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl install "$SIM" "$APP"
echo "[sim-build] installed $BUNDLE on $SIM"
