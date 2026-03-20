#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="${ROOT}/ios/App/App/Assets.xcassets"
ICON_DIR="${ASSETS_DIR}/AppIcon.appiconset"
SPLASH_DIR="${ASSETS_DIR}/Splash.imageset"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

BASE_PNG="${TMP_DIR}/base.png"

mkdir -p "${ICON_DIR}" "${SPLASH_DIR}"

python3 - <<'PY' "${BASE_PNG}"
import struct
import zlib
import sys

out = sys.argv[1]
width = 1
height = 1
pixel = b"\x00\x16\x23\x36"
raw = b"\x00" + pixel

def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )

ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
png = (
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", ihdr)
    + chunk(b"IDAT", zlib.compress(raw, 9))
    + chunk(b"IEND", b"")
)

with open(out, "wb") as fh:
    fh.write(png)
PY

sips_resize() {
  local width="$1"
  local height="$2"
  local out="$3"
  sips --resampleHeightWidth "${height}" "${width}" "${BASE_PNG}" --out "${out}" >/dev/null
}

ensure_png() {
  local width="$1"
  local height="$2"
  local out="$3"
  if [ -f "${out}" ]; then
    return
  fi
  sips_resize "${width}" "${height}" "${out}"
}

ensure_png 1024 1024 "${ICON_DIR}/AppIcon-512@2x.png"
ensure_png 2732 2732 "${SPLASH_DIR}/splash-2732x2732.png"
ensure_png 2732 2732 "${SPLASH_DIR}/splash-2732x2732-1.png"
ensure_png 2732 2732 "${SPLASH_DIR}/splash-2732x2732-2.png"

printf 'Ensured iOS placeholder assets in %s\n' "${ASSETS_DIR}"
