#!/usr/bin/env bash
# Update ONLY already-installed bounty worker/publisher Python filters.
# Never touches VPN, scanner jobs, OAuth/PAT files, systemd units or timers.
set -euo pipefail
umask 077

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run from your root Termius VPS session." >&2
  exit 1
fi
if ! command -v curl >/dev/null || ! command -v python3 >/dev/null; then
  echo "curl and python3 are required; no changes made." >&2
  exit 1
fi

# Immutable commit containing vetted false-positive fix and its regression tests.
REF="57602cb19e3d75bec250ffa66f807dc1cfb73038"
BASE="https://raw.githubusercontent.com/Trelliz/bounty-workbench/${REF}/scripts"
targets=()
for candidate in \
  /opt/bounty-copilot/bridge.py \
  /opt/bounty-copilot/bounty_copilot_bridge.py \
  /opt/bounty-inbox-publisher/bounty_copilot_bridge.py \
  /opt/bounty-inbox-publisher/publish_scanner_queue.py; do
  if [[ -L "$candidate" ]]; then
    echo "Refusing symlink target: $candidate; no changes made." >&2
    exit 1
  fi
  if [[ -f "$candidate" ]]; then
    targets+=("$candidate")
  fi
done
if [[ "${#targets[@]}" -eq 0 ]]; then
  echo "No existing bounty filters found on this VPS; no changes made." >&2
  exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
for filename in bounty_copilot_bridge.py publish_scanner_queue.py; do
  curl --fail --silent --show-error --location --max-time 45 \
    "${BASE}/${filename}" --output "${stage}/${filename}"
done
python3 -m py_compile "$stage/bounty_copilot_bridge.py" "$stage/publish_scanner_queue.py"

# Stage all local replacements before altering any installed Python source.
for candidate in "${targets[@]}"; do
  if [[ "$candidate" == */publish_scanner_queue.py ]]; then
    src="$stage/publish_scanner_queue.py"
  else
    src="$stage/bounty_copilot_bridge.py"
  fi
  install -m 0644 -o root -g root "$src" "${candidate}.new.$$"
done
for candidate in "${targets[@]}"; do
  mv -f -T -- "${candidate}.new.$$" "$candidate"
  echo "Updated: $candidate"
done

echo
echo "Updated installed GitHub bounty filters from commit $REF."
echo "No scanner jobs, authentication, network/VPN settings, timers or AI billing changed."
echo "The existing service/timer will use these filters on its NEXT run."
echo "Inspect: journalctl -u bounty-inbox-publisher.service -n 25 --no-pager"
echo "Inspect: journalctl -u bounty-copilot-bridge.service -n 25 --no-pager"
