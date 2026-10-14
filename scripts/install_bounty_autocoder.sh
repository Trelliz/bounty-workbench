#!/usr/bin/env bash
# One-time upgrade: keep the existing scanner + Copilot OAuth. Replace
# Copilot triage with automatic UNSUBMITTED patch generation.
set -euo pipefail
umask 077
if [ "$(id -u)" != 0 ]; then echo 'Please use your root Termius VPS session.' >&2; exit 1; fi
if [ ! -d /var/lib/btc-bounty-hunter/jobs ] || [ ! -d /var/lib/bounty-copilot/.copilot ]; then
  echo 'The existing scanner/Copilot bridge must be installed first.' >&2; exit 1
fi
if [ ! -s /var/lib/bounty-copilot/.copilot/config.json ]; then
  echo 'The existing Copilot OAuth login is unavailable; no changes made.' >&2; exit 1
fi
if ! id bountycopilot >/dev/null 2>&1; then echo 'bountycopilot account missing'; exit 1; fi
if ! command -v git >/dev/null 2>&1; then
  echo 'Git is needed: apt-get update && apt-get install git'; exit 1
fi
if [ ! -x /usr/local/bin/copilot ]; then echo 'Copilot CLI missing'; exit 1; fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BASE=https://raw.githubusercontent.com/Trelliz/bounty-workbench/main/scripts
for F in bounty_copilot_bridge.py bounty_autocoder.py; do
  curl --fail --silent --show-error --location --max-time 35 \
    "$BASE/$F" --output "$TMP/$F"
done
python3 -m py_compile "$TMP/bounty_copilot_bridge.py" "$TMP/bounty_autocoder.py"
install -m 0644 -o root -g root "$TMP/bounty_copilot_bridge.py" /opt/bounty-copilot/bounty_copilot_bridge.py
install -m 0644 -o root -g root "$TMP/bounty_autocoder.py" /opt/bounty-copilot/bounty_autocoder.py
install -d -m 0700 -o bountycopilot -g bountycopilot /var/lib/bounty-copilot/code-reports

# First check eligibility without downloading code or spending Copilot credits.
echo 'Checking scanner queue (no AI requests, no code downloaded)...'
runuser -u bountycopilot -- env HOME=/var/lib/bounty-copilot \
  python3 /opt/bounty-copilot/bounty_autocoder.py --dry-run || true

echo 'Upgrading ONE existing timer/service, not adding additional AI requests...'
systemctl stop bounty-copilot-bridge.timer || true
systemctl stop bounty-copilot-bridge.service || true
cat > /etc/systemd/system/bounty-copilot-bridge.service <<'UNIT'
[Unit]
Description=Bounded Copilot autonomous PATCH DRAFT worker (no PR submission)
After=network-online.target bounty-hunter.service
Wants=network-online.target

[Service]
Type=oneshot
User=bountycopilot
Group=bountycopilot
SupplementaryGroups=bountyhunter
WorkingDirectory=/var/lib/bounty-copilot
Environment=HOME=/var/lib/bounty-copilot
Environment=XDG_CONFIG_HOME=/var/lib/bounty-copilot/.config
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 /opt/bounty-copilot/bounty_autocoder.py
TimeoutStartSec=8min
MemoryMax=390M
CPUQuota=75%
NoNewPrivileges=true
CapabilityBoundingSet=
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/bounty-copilot
UMask=0077
UNIT
cat > /etc/systemd/system/bounty-copilot-bridge.timer <<'UNIT'
[Unit]
Description=Check scanner leads every 15 minutes for Copilot patch drafting

[Timer]
OnBootSec=3min
OnUnitInactiveSec=15min
Persistent=false
Unit=bounty-copilot-bridge.service

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now bounty-copilot-bridge.timer
echo
echo 'DONE: Automatic source PATCH drafting installed; no payment / PR submission.'
echo 'Checks every ~15 minutes. At most ONE Copilot AI request per UTC day'
echo '(shared with the old triage service; no guarantee of a working patch).'
echo 'It only uses the existing device OAuth login, never your personal-access-token secret.'
echo 'See pending jobs: ls -l /var/lib/btc-bounty-hunter/jobs'
echo 'See result metadata: find /var/lib/bounty-copilot/code-reports -name result.json'
echo 'See worker logs: journalctl -u bounty-copilot-bridge.service -n 25 --no-pager'
echo 'STOP all AI scheduling: systemctl disable --now bounty-copilot-bridge.timer'
