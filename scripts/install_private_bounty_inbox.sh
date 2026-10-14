#!/usr/bin/env bash
# One-time, least-privilege VPS -> PRIVATE GitHub Issues bounty inbox setup.
# Does not modify VPN, networking, firewall, Copilot configuration, or scanner.
set -euo pipefail
umask 077
if [[ "$(id -u)" -ne 0 ]]; then
  echo 'Please run as root from your interactive Termius shell.' >&2
  exit 1
fi
if [[ ! -t 0 ]]; then
  echo 'Run this from an interactive terminal (do not pipe it into bash).' >&2
  exit 1
fi
if ! id bountyhunter >/dev/null 2>&1; then
  echo 'Existing bountyhunter user not found. Refusing to create/change accounts.' >&2
  exit 1
fi
if [[ ! -d /var/lib/btc-bounty-hunter/jobs ]]; then
  echo 'Scanner queue directory not found. No changes made.' >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo 'curl not found.' >&2
  exit 1
fi
DEST='Trelliz/bounty-inbox'
CODE_REF='d22bd25c2a9f61056228d8eb5c5b7ae04724901b'
CODE_BASE="https://raw.githubusercontent.com/Trelliz/bounty-workbench/${CODE_REF}/scripts"
INSTALL_DIR='/opt/bounty-inbox-publisher'
STATE_DIR='/var/lib/bounty-inbox-publisher'
TOKEN_FILE="${STATE_DIR}/token"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo 'Downloading pinned, public helper source code...'
curl --fail --silent --show-error --location --max-time 40   "${CODE_BASE}/bounty_copilot_bridge.py" --output "${STAGE}/bounty_copilot_bridge.py"
curl --fail --silent --show-error --location --max-time 40   "${CODE_BASE}/publish_scanner_queue.py" --output "${STAGE}/publish_scanner_queue.py"
/usr/bin/python3 -m py_compile "${STAGE}/bounty_copilot_bridge.py" "${STAGE}/publish_scanner_queue.py"
install -d -m 0755 -o root -g root "$INSTALL_DIR"
install -m 0644 -o root -g root "${STAGE}/bounty_copilot_bridge.py" "${INSTALL_DIR}/bounty_copilot_bridge.py"
install -m 0644 -o root -g root "${STAGE}/publish_scanner_queue.py" "${INSTALL_DIR}/publish_scanner_queue.py"
install -d -m 0700 -o bountyhunter -g bountyhunter "$STATE_DIR"

echo
echo "GitHub token required for private repository: ${DEST}"
echo 'Required scope: ONLY this repository, Issues read/write, Metadata read.'
echo 'Paste it here, NOT in ChatGPT. Input will be hidden.'
IFS= read -r -s -p 'Fine-grained token: ' TOKEN
printf '\n'
if [[ -z "$TOKEN" || "$TOKEN" == *[$'\r\n\t\ ']* ]]; then
  echo 'Invalid token; aborting.' >&2
  unset TOKEN
  exit 1
fi
install -m 0600 -o bountyhunter -g bountyhunter /dev/null "$TOKEN_FILE"
printf '%s' "$TOKEN" > "$TOKEN_FILE"
unset TOKEN
chmod 0600 "$TOKEN_FILE"
chown bountyhunter:bountyhunter "$TOKEN_FILE"

echo 'Checking scanner candidates without publishing...'
runuser -u bountyhunter -- /usr/bin/python3 "${INSTALL_DIR}/publish_scanner_queue.py" --destination "$DEST"
echo 'Validating private GitHub permissions and publishing up to 3 suitable leads...'
runuser -u bountyhunter -- /usr/bin/python3 "${INSTALL_DIR}/publish_scanner_queue.py" --destination "$DEST" --token-file "$TOKEN_FILE" --publish

# No shell spawned as root by this service. No VPN config/network settings touched.
cat > /etc/systemd/system/bounty-inbox-publisher.service <<'UNIT'
[Unit]
Description=Publish filtered public coding bounty links to private GitHub inbox
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bountyhunter
Group=bountyhunter
Environment=HOME=/var/lib/bounty-inbox-publisher
WorkingDirectory=/var/lib/bounty-inbox-publisher
ExecStart=/usr/bin/python3 /opt/bounty-inbox-publisher/publish_scanner_queue.py --destination Trelliz/bounty-inbox --token-file /var/lib/bounty-inbox-publisher/token --publish
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
PrivateTmp=true
PrivateDevices=true
MemoryMax=250M
CPUQuota=50%
CapabilityBoundingSet=
ReadWritePaths=/var/lib/bounty-inbox-publisher
TimeoutStartSec=8min
UMask=0077
UNIT

cat > /etc/systemd/system/bounty-inbox-publisher.timer <<'UNIT'
[Unit]
Description=Check bounty scanner queue and publish at most 10 leads/day
[Timer]
OnBootSec=4min
OnUnitInactiveSec=15min
Persistent=false
Unit=bounty-inbox-publisher.service
[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now bounty-inbox-publisher.timer
echo
echo 'Bounty inbox publisher is now enabled.'
echo 'Only public issue URLs and unverified amounts are uploaded to the private repo.'
echo 'GitHub and Copilot paid usage is NOT enabled.'
echo 'Status: systemctl status bounty-inbox-publisher.timer --no-pager'
echo 'Logs: journalctl -u bounty-inbox-publisher.service -n 20 --no-pager'
echo 'STOP: systemctl disable --now bounty-inbox-publisher.timer'
