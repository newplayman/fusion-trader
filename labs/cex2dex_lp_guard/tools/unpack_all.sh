#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEG="$LAB_DIR/replay/segments"
OUT="$LAB_DIR/replay/unpacked"
mkdir -p "$OUT"

shopt -s nullglob
for f in "$SEG"/*.tar.zst "$SEG"/*.tar.gz "$SEG"/*.tgz "$SEG"/*.tar; do
  name="$(basename "$f" | sed 's/\..*//')"
  tgt="$OUT/$name"
  mkdir -p "$tgt"
  if [[ "$f" == *.tar.zst ]]; then
    if command -v unzstd >/dev/null 2>&1; then
      tar --use-compress-program=unzstd -xf "$f" -C "$tgt"
    elif command -v zstd >/dev/null 2>&1; then
      zstd -d -c "$f" | tar -xf - -C "$tgt"
    else
      echo "ERROR: need 'unzstd' or 'zstd' to unpack: $f" >&2
      exit 2
    fi
  elif [[ "$f" == *.tar.gz || "$f" == *.tgz ]]; then
    tar -xzf "$f" -C "$tgt"
  else
    tar -xf "$f" -C "$tgt"
  fi
done
