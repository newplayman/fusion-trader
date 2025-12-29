#!/usr/bin/env bash
set -euo pipefail

# Installs/updates a read-only sidecar hourly packer on the VPS.
# It only reads from /var/log/alcova and writes archives to /var/log/alcova/segments.
# It does NOT restart or modify any trading process.
#
# Usage:
#   VPS_HOST=root@1.2.3.4 bash vps_install_packer.sh

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VPS_HOST="${VPS_HOST:-${1:-}}"

if [ -z "$VPS_HOST" ]; then
  echo "ERROR: VPS_HOST required (e.g. root@<VPS_IP>)" >&2
  exit 2
fi

ssh "$VPS_HOST" 'bash -s' <<'VPS_EOF'
set -euo pipefail

BASE="/var/log/alcova"
OUT="/var/log/alcova/segments"
mkdir -p "$OUT"

SCRIPT="/usr/local/bin/pack_segments_hourly.sh"
cat > "$SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="/var/log/alcova"
OUT="/var/log/alcova/segments"
NOW_UTC="$(date -u +%Y%m%dT%H00Z)"
TMP="$(mktemp -d)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Read-only sidecar copy: files modified in last 70 minutes (exclude segments dir)
find "$BASE" -type f -mmin -70 ! -path "$OUT/*" -exec cp --parents {} "$TMP/" \;

if [ "$(find "$TMP" -type f | wc -l)" -eq 0 ]; then
  exit 0
fi

if command -v zstd >/dev/null 2>&1; then
  ARCH="$OUT/seg_${NOW_UTC}.tar.zst"
  tar --use-compress-program=zstd -cf "$ARCH" -C "$TMP" .
else
  ARCH="$OUT/seg_${NOW_UTC}.tar.gz"
  tar -czf "$ARCH" -C "$TMP" .
fi
EOF
chmod +x "$SCRIPT"

if command -v systemctl >/dev/null 2>&1; then
  SERVICE="/etc/systemd/system/alcova-pack-segments.service"
  TIMER="/etc/systemd/system/alcova-pack-segments.timer"

  cat > "$SERVICE" <<'EOF'
[Unit]
Description=Pack Alcova logs to hourly segments (read-only sidecar)

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pack_segments_hourly.sh
Nice=10
IOSchedulingClass=idle
EOF

  cat > "$TIMER" <<'EOF'
[Unit]
Description=Hourly pack of Alcova log segments

[Timer]
OnCalendar=hourly
Persistent=false

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now alcova-pack-segments.timer
  echo "systemd_timer=enabled"
else
  # Fallback: cron.hourly (common on many distros). Kept idempotent by overwrite.
  CRON="/etc/cron.hourly/alcova-pack-segments"
  cat > "$CRON" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
/usr/local/bin/pack_segments_hourly.sh
EOF
  chmod +x "$CRON"
  echo "cron_hourly=installed"
fi

echo "installed=$SCRIPT"
VPS_EOF

echo "vps_install_ok=1"
