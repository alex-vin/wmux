#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/prune-release-bundle.sh <path-to-app-bundle>

Prunes bloat assets from release app bundle:
- Removes Computer Use.app helper
- Prunes redundant localization files (keeps only en and zh-Hans)
- Prunes unused highlight theme CSS files
EOF
}

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

APP_PATH="$1"
if [ ! -d "$APP_PATH/Contents" ]; then
  echo "error: app bundle not found: $APP_PATH" >&2
  exit 1
fi

echo "=== Pruning Bloat Assets from $APP_PATH ==="

# 1. Remove Computer Use.app helper (-13MB)
if [ -d "$APP_PATH/Contents/Library/cmux Computer Use.app" ]; then
  echo "Removing Computer Use helper..."
  rm -rf "$APP_PATH/Contents/Library/cmux Computer Use.app"
fi
find "$APP_PATH/Contents/Library" -maxdepth 1 -name "*Computer Use*" -exec rm -rf {} + 2>/dev/null || true

# 2. Prune redundant localization lproj directories (-10.1MB)
# Keep only en, zh-Hans, and Base
echo "Pruning non-essential localizations..."
for lproj in "$APP_PATH/Contents/Resources"/*.lproj; do
  [ -d "$lproj" ] || continue
  bname="$(basename "$lproj")"
  case "$bname" in
    en.lproj|zh-Hans.lproj|Base.lproj)
      # keep
      ;;
    *)
      rm -rf "$lproj"
      ;;
  esac
done

# Also check bundles in Resources for localized folders
for bundle in "$APP_PATH/Contents/Resources"/*.bundle; do
  [ -d "$bundle" ] || continue
  for lproj in "$bundle"/*.lproj "$bundle/Contents/Resources"/*.lproj; do
    [ -d "$lproj" ] || continue
    bname="$(basename "$lproj")"
    case "$bname" in
      en.lproj|zh-Hans.lproj|Base.lproj)
        # keep
        ;;
      *)
        rm -rf "$lproj"
        ;;
    esac
  done
done

# 3. Highlightr theme stylesheet pruning (-1.8MB)
# Keep default dark/light themes, prune esoteric styles
HL_DIR="$APP_PATH/Contents/Resources/Highlightr_Highlightr.bundle/Contents/Resources"
if [ -d "$HL_DIR" ]; then
  echo "Pruning redundant Highlightr styles..."
  find "$HL_DIR" -name "*.css" \
    ! -name "github*.css" \
    ! -name "atom-one*.css" \
    ! -name "xcode*.css" \
    ! -name "monokai*.css" \
    ! -name "vs2015.css" \
    ! -name "default.css" \
    ! -name "solarized*.css" \
    -delete 2>/dev/null || true
fi

# 4. Direct wmux CLI branding (remove cmux binary completely)
if [ -f "$APP_PATH/Contents/Resources/bin/cmux" ]; then
  echo "Renaming CLI binary from cmux directly to wmux..."
  mv -f "$APP_PATH/Contents/Resources/bin/cmux" "$APP_PATH/Contents/Resources/bin/wmux"
fi
rm -f "$APP_PATH/Contents/Resources/bin/cmux"

# 5. Eliminate external private frameworks (0 bytes guarantee)
rm -rf "$APP_PATH/Contents/Frameworks" 2>/dev/null || true

echo "Pruning complete."
