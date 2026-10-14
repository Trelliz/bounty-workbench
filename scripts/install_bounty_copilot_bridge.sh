#!/usr/bin/env bash
# Connect installed scanner to GitHub Copilot CLI, using existing device OAuth.
# No payment method, no token output, no repository submission.
set -euo pipefail
umask 077
if [ "$(id -u)" -ne 0 ]; then echo 'Run as root (your Termius login).' >&2; exit 1; fi
SCANNER=/var/lib/btc-bounty-hunter/jobs
CLI=/usr/local/bin/copilot
SRC=https://raw.githubusercontent.com/Trelliz/bounty-workbench/main/scripts/bounty_copilot_bridge.py
if [ ! -d "$SCANNER" ]; then echo 'Scanner queue missing; is bounty-hunter installed?' >&2; exit 1; fi
if ! id bountyhunter >/dev/null 2>&1; then echo 'Scanner account bountyhunter missing.' >&2; exit 1; fi
if [ ! -x "$CLI" ]; then echo 'Copilot CLI missing from /usr/local/bin/copilot.' >&2; exit 1; fi
if [ ! -s /root/.copilot/config.json ]; then
  echo 'Copilot device OAuth login missing. First run copilot login --device-code.' >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then echo 'curl is required.' >&2; exit 1; fi
if ! id bountycopilot >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/bounty-copilot --shell /usr/sbin/nologin --groups bountyhunter bountycopilot
fi
install -d -m 0755 -o root -g root /opt/bounty-copilot
install -d -m 0700 -o bountycopilot -g bountycopilot /var/lib/bounty-copilot
install -d -m 0700 -o bountycopilot -g bountycopilot /var/lib/bounty-copilot/.copilot
install -d -m 0700 -o bountycopilot -g bountycopilot /var/lib/bounty-copilot/reports
# Copy the previously approved device-OAuth session locally into a dedicated service account.
# The copied credential stays on the VPS (NOT in the public repository).
install -m 0600 -o bountycopilot -g bountycopilot /root/.copilot/config.json /var/lib/bounty-copilot/.copilot/config.json
# Let only the dedicated group read scanner queue JSON.
chgrp bountyhunter /var/lib/btc-bounty-hunter "$SCANNER"
chmod 0750 /var/lib/btc-bounty-hunter "$SCANNER"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl --fail --silent --show-error --location --max-time 30 "$SRC" --output "$TMP"
python3 -m py_compile "$TMP"
install -m 0644 -o root -g root "$TMP" /opt/bounty-copilot/bridge.py
cat > /etc/systemd/system/bounty-copilot-bridge.service <<'UNIT'
[Unit]
Description=Read-only capped Copilot triage for bounty scanner leads
Wants=network-online.target
After=network-online.target bounty-hunter.service

[Service]
Type=oneshot
User=bountycopilot
Group=bountycopilot
SupplementaryGroups=bountyhunter
WorkingDirectory=/var/lib/bounty-copilot
Environment=HOME=/var/lib/bounty-copilot
Environment=XDG_CONFIG_HOME=/var/lib/bounty-copilot/.config
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 /opt/bounty-copilot/bridge.py
MemoryMax=310M
CPUQuota=50%
TimeoutStartSec=7min
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
Description=Check bounty lead queue every 15min, max one Copilot review per UTC day

[Timer]
OnBootSec=4min
OnUnitInactiveSec=15min
Persistent=false
Unit=bounty-copilot-bridge.service

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now bounty-copilot-bridge.timer
# Pure scanner metadata check. This part does not call Copilot or use AI credits.
runuser -u bountycopilot -- /usr/bin/python3 /opt/bounty-copilot/bridge.py --dry-run || true
printf '\nBridge installed. Checks scanner jobs every 15 minutes; max 1 Copilot triage/day.\n'
printf 'Never clones repositories, executes outsider code, or submits PRs.\n'
printf 'See timer: systemctl list-timers bounty-copilot-bridge.timer --no-pager\n'
printf 'See reports: ls -l /var/lib/bounty-copilot/reports\n'
printf 'See logs: journalctl -u bounty-copilot-bridge -n 20 --no-pager\n'
printf 'STOP AI calls: systemctl disable --now bounty-copilot-bridge.timer\n'
