#!/usr/bin/env bash
set -euo pipefail

# Build and package wmux/cmux into DMG locally with step timing and performance profiling

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

START_TIME=$(date +%s)
step_start=$START_TIME

log_step() {
  local now=$(date +%s)
  local elapsed=$((now - step_start))
  echo "⏱️  [$1] took ${elapsed}s"
  step_start=$now
}

echo "=== 1. Checking Build Toolchain ==="
for tool in xcodebuild rustc cargo go create-dmg codesign; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Missing required tool: $tool" >&2
    exit 1
  fi
done
echo "Xcode: $(xcodebuild -version | head -1)"
echo "Rustc: $(rustc --version)"
echo "Go: $(go version)"
echo "create-dmg: $(create-dmg --version)"
log_step "Toolchain validation"

echo "=== 2. Checking GhosttyKit Framework ==="
if [ ! -d "GhosttyKit.xcframework" ]; then
  echo "GhosttyKit.xcframework not found! Attempting download or build..."
  if [ -f "scripts/download-prebuilt-ghosttykit.sh" ]; then
    export GHOSTTY_SHA="cb1ef7091cdef0b581ee2cbd83742b653253523e"
    ./scripts/download-prebuilt-ghosttykit.sh
  else
    echo "❌ Cannot find GhosttyKit.xcframework or download script!" >&2
    exit 1
  fi
else
  echo "GhosttyKit.xcframework exists."
fi
log_step "GhosttyKit preparation"

echo "=== 3. Compiling macOS Application via xcodebuild (Release) ==="
export GIT_TERMINAL_PROMPT=0
export CARGO_NET_TIMEOUT=30
export CARGO_NET_GIT_FETCH_WITH_CLI="true"
export CMUX_SWIFT_FRONTEND_WORKAROUND=1
export CMUX_SWIFT_DISABLE_GLOBAL_ISEL=1
export CMUX_SKIP_ZIG_BUILD=1

# Run xcodebuild with timing summary
xcodebuild -scheme cmux \
  -configuration Release \
  -derivedDataPath build \
  -destination 'generic/platform=macOS' \
  ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  DEBUG_INFORMATION_FORMAT=dwarf \
  GCC_GENERATE_DEBUGGING_SYMBOLS=NO \
  OTHER_SWIFT_FLAGS='$(inherited) -Xllvm -aarch64-enable-global-isel-at-O=-1' \
  -showBuildTimingSummary \
  build

log_step "xcodebuild Release build"

echo "=== 4. Identifying Produced App Bundle ==="
if [ -d "build/Build/Products/Release/wmux.app" ]; then
  APP_PATH="build/Build/Products/Release/wmux.app"
  APP_NAME="wmux.app"
elif [ -d "build/Build/Products/Release/cmux.app" ]; then
  APP_PATH="build/Build/Products/Release/cmux.app"
  APP_NAME="cmux.app"
else
  echo "❌ Build output not found in build/Build/Products/Release/" >&2
  exit 1
fi
echo "Found application bundle: $APP_PATH"

echo "=== 5. Ad-hoc Codesigning App Bundle ==="
codesign --force --deep -s - "$APP_PATH"
log_step "Codesigning"

echo "=== 6. Packaging DMG ==="
mkdir -p dist
DMG_PATH="dist/wmux-macos-arm64.dmg"
rm -f "$DMG_PATH" dist/rw.*.dmg 2>/dev/null || true

# LC_ALL=C is critical so that create-dmg's regex matches English "Resource busy"
# on non-English locales during hdiutil detach retries.
export LC_ALL=C
create-dmg \
  --volname "wmux" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME" 175 120 \
  --app-drop-link 425 120 \
  --hide-extension "$APP_NAME" \
  --hdiutil-retries 10 \
  --overwrite \
  "$DMG_PATH" \
  "$APP_PATH"

log_step "DMG packaging"

TOTAL_TIME=$(( $(date +%s) - START_TIME ))
echo ""
echo "=========================================="
echo "🎉 Build & Packaging Completed Successfully!"
echo "Total Time: ${TOTAL_TIME}s"
echo "DMG Output: $DMG_PATH"
echo "DMG Size:   $(du -h "$DMG_PATH" | cut -f1)"
echo "App Size:   $(du -sh "$APP_PATH" | cut -f1)"
echo "=========================================="
