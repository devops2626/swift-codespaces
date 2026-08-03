#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://127.0.0.1:8080}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SAMPLE="${ROOT}/Samples/sample.png"

echo "== health =="
curl -sf "$BASE/health"
echo

if [[ ! -f "$SAMPLE" ]]; then
  echo "Missing $SAMPLE — generating a tiny PNG with Python if available, else skip analyze"
  if command -v python3 >/dev/null 2>&1; then
    mkdir -p "${ROOT}/Samples"
    python3 - <<'PY'
from pathlib import Path
# 1x1 red PNG
import struct, zlib
def chunk(tag, data):
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
raw = b'\x00' + b'\xfc\x00\x00'  # filter + RGB for 1 pixel roughly — use fixed known PNG instead
png = bytes([
  0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,
  0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
  0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,
  0x08,0x02,0x00,0x00,0x00,0x90,0x77,0x53,0xDE,
  0x00,0x00,0x00,0x0C,0x49,0x44,0x41,0x54,
  0x08,0xD7,0x63,0xF8,0xCF,0xC0,0x00,0x00,
  0x03,0x01,0x01,0x00,0x18,0xDD,0x8D,0xB4,
  0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,
  0xAE,0x42,0x60,0x82
])
Path('Samples/sample.png').write_bytes(png)
print('wrote Samples/sample.png')
PY
  else
    echo "No sample image; create Samples/sample.png and re-run"
    exit 1
  fi
fi

echo "== analyze (no ocr) =="
curl -sf -H "Content-Type: image/png" --data-binary @"$SAMPLE" "$BASE/analyze"
echo

echo "== analyze (ocr=true) =="
curl -sf -H "Content-Type: image/png" --data-binary @"$SAMPLE" "$BASE/analyze?ocr=true"
echo

echo "smoke ok"
