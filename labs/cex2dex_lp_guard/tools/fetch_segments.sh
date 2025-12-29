#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_DIR="$LAB_DIR/replay/segments"
mkdir -p "$LOCAL_DIR"

VPS_HOST="${VPS_HOST:-${1:-}}"
VPS_DIR="${VPS_DIR:-${2:-/var/log/alcova/segments}}"

if [ -z "$VPS_HOST" ]; then
  echo "ERROR: VPS_HOST required" >&2
  echo "Example: VPS_HOST=root@1.2.3.4 bash $0" >&2
  exit 2
fi

if command -v rsync >/dev/null 2>&1; then
  rsync -av --progress "$VPS_HOST:$VPS_DIR/" "$LOCAL_DIR/"
else
  scp -r "$VPS_HOST:$VPS_DIR/"* "$LOCAL_DIR/" || true
fi
