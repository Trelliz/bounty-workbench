#!/usr/bin/env bash
# Interactive Copilot CLI OAuth check: runs only when user executes it on their own server.
# Nothing scheduled or submitted, and no personal access token is requested.
set -euo pipefail
umask 077
export HOME="${HOME:-/root}"
printf '\nCopilot CLI OAuth diagnostic — no payments, no repository submission.\n'
printf 'This signs in using GitHub’s official DEVICE authorization in your Termius session.\n'
printf 'Review the permissions GitHub shows before authorizing.\n\n'
if ! command -v curl >/dev/null 2>&1; then
  printf 'Please install curl first: apt-get update && apt-get install -y curl\n'
  exit 2
fi
available_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
if [[ "$available_kb" =~ ^[0-9]+$ ]] && (( available_kb < 350000 )); then
  printf 'Stopping: less than 350 MB free disk space. No installation attempted.\n'
  exit 3
fi
if ! command -v copilot >/dev/null 2>&1; then
  printf 'Downloading GitHub’s official Copilot CLI installer...\n'
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fLsS --max-time 45 'https://gh.io/copilot-install' -o "$installer"
  bash "$installer"
fi
if ! command -v copilot >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
fi
if ! command -v copilot >/dev/null 2>&1; then
  echo 'Installation did not put Copilot CLI on PATH; no login attempted.'
  exit 4
fi
echo "Installed Copilot CLI version:"
copilot --version
echo
echo 'Next: Copy the short code displayed below into GitHub’s device authorization page.'
echo 'Do not paste any codes, tokens, or passwords into ChatGPT.'
echo
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN copilot login --device-code
echo
echo 'Testing one harmless request on your existing Copilot Free entitlement...'
env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
 copilot -p 'Reply with exactly READY. Do not use tools or access files.' \
 --max-ai-credits=30 --no-ask-user --disable-builtin-mcps --available-tools=view -s
printf '\nOAuth CLI test completed. No code submitted and no tasks scheduled.\n'
