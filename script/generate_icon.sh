#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT_DIR/build/AppIcon.iconset"
SOURCE="$ROOT_DIR/Assets/AppIcon-1024.png"
OUTPUT="$ROOT_DIR/Resources/AppIcon.icns"

cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/build/ModuleCache"
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/build/ModuleCache" swift script/prepare_icon.swift

rm -rf "$ICONSET"
mkdir -p "$ICONSET" "$ROOT_DIR/Resources" "$ROOT_DIR/build/tmp"

sips -z 16 16 "$SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

if ! TMPDIR="$ROOT_DIR/build/tmp" iconutil -c icns "$ICONSET" -o "$OUTPUT"; then
  if [[ -f "$OUTPUT" ]]; then
    echo "iconutil failed in this environment; keeping existing $OUTPUT"
  else
    exit 1
  fi
fi
echo "Wrote $OUTPUT"
