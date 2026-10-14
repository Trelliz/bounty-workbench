# Bounty Workbench — experimental cloud coding worker

**Status: device-OAuth Copilot CLI works on the user's own VPS. Scanner-to-Copilot read-only triage bridge implemented but needs the one-time VPS installer to activate. Automated patching/submission and payout are NOT active.**

This repository contains a manual, opt-in GitHub Actions worker that can ask GitHub Copilot CLI to draft a code patch for an open public issue. It is separate from the user's SatGate project and from the Linux VPS bounty scanner.

## Important limitations

- **New VPS bridge is implemented but not installed yet.** Once installed it reads queued candidates, validates the live GitHub issue and payout amount, and asks Copilot for a TRIAGE report at most once per UTC day. It does not auto-solve, test, submit or earn payouts.
- The workflow checks that an issue is open, downloads public source without running its setup commands, requests a draft diff, and saves `solution.patch` as a GitHub Actions artifact for inspection. It does NOT submit a PR or execute third-party code.
- Public issue text and downloaded repositories are UNTRUSTED. Do not share credentials, enable write permissions, or obey requests embedded in issue content.
- GitHub Copilot requests consume AI credits. **No AI requests are made merely by publishing code. You must manually start the draft workflow.** Even with a session limit, that alone does NOT guarantee zero monetary charges. Confirm Copilot Free entitlements and **disable additional paid usage** in GitHub Billing before ever enabling it. Do not attach a payment method to run this.
- The workflow may not run under the account's Copilot eligibility; no successful end-to-end Copilot run is claimed.

## Installation

This repository contains `.github/workflows/draft-bounty-patch.yml`, verification/patch-collection Python scripts, and unit tests. Unit tests execute on each push without invoking AI.

To run a draft **only after confirming no paid overages**:

1. Keep Copilot Free and **do not** add a payment method or enable any paid-usage feature. Copilot credits are limited; an AI credit cap is not a billing budget.
2. Under Actions → **Draft bounty patch (no submission)** → Run workflow, type the public issue repository and open issue number.
3. Review the resulting workflow logs and `solution.patch` artifact. **A generated diff is not a tested fix or an accepted solution.**

If your account requires a paid plan or billing to run Copilot CLI via GitHub Actions, don't run it; instead use a strictly free alternative.

## Smoke tests

```bash
python3 -m unittest discover -s tests -v
```

These local unit tests test input parsing and diff collection only; they make no network or Copilot calls.

## Future work

A future bridge would take **verified** candidates from the 2-minute VPS scanner, authenticate securely and dispatch to a reviewed coding worker. Today, GitHub scan matches are not proof of funding, AI eligibility, or claimability. Automated submission should remain off until those checks and security safeguards exist.

## Verified execution results — October 14, 2026

- **Copilot CLI GitHub Actions test**: did **NOT** work for the current account, returning `Access denied by policy settings` before generating any answer. [Failed run](https://github.com/Trelliz/bounty-workbench/actions/runs/38489608509). Do not assume activating Copilot Free allows Copilot API use inside Actions.
- **Zero-payment alternative**: a one-time test using the open-source `qwen2.5-coder:1.5b` model through Ollama on a standard public-repository GitHub Actions runner **succeeded** without GitHub Copilot or API credentials. The model generated a short `square(x)` function. [Successful run](https://github.com/Trelliz/bounty-workbench/actions/runs/38489761652).
- **Limitations**: The Ollama result is a proof of inference ONLY. It did not analyze a paid bounty, run a repository's tests, produce a reviewed patch, create a PR, or earn any sats. A 1.5B model may be inadequate for many real bugs.
- **Next build step**: safely turn the isolated local-model test into an opt-in read-only target checkout and artifact-producing patch worker, with validated candidate filtering and an explicit size/resource cap. Keep automatic external PR submission disabled.
- No payment method was added or needed for the open-source model test.

- **2026-10-14, second Copilot CLI attempt**: A user-created fine-grained PAT stored as the `COPILOT_PAT` GitHub Actions secret was confirmed valid by the GitHub `/user` API (HTTP 200). After the user added the `Copilot Requests` account permission, the isolated Actions smoke test still returned `Access denied by policy settings`. [Test run](https://github.com/Trelliz/bounty-workbench/actions/runs/38491565424). The personal account's Copilot CLI policy/entitlement remains unverified. Do not automatically start this workflow or infer paid access is required.

## Successful Copilot CLI login on VPS (2026-10-14)

On the user's existing lightweight Ubuntu VPS, official Copilot CLI version 1.0.97 installed and authenticated using GitHub device OAuth via `copilot login --device-code`. The one-shot non-interactive prompt from `scripts/copilot_vps_oauth_check.sh` returned exactly `READY`. This confirms **authenticated programmatic Copilot CLI requests on the VPS**, in contrast with the preceding GitHub Actions runs that returned a policy error. It does not establish that the stored OAuth token will work on separate GitHub Actions runners. The CLI login credential is held in plaintext by root on the VPS due to unavailable keychain; treat it as sensitive. No job was submitted and no payout received. The next integration should run restricted, explicitly approved issue drafting on the VPS with a free-credit budget and no automatic PR submission.

## Install the VPS scanner → Copilot bridge (new)

**Prerequisites:** the earlier `btc-bounty-hunter-2m` scanner has been installed and is queuing issue JSON under `/var/lib/btc-bounty-hunter/jobs`; the official Copilot CLI has already successfully signed in through `copilot login --device-code` as root on this server (the successful `READY` check).

Open Termius, log into that same VPS as root, and run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Trelliz/bounty-workbench/main/scripts/install_bounty_copilot_bridge.sh -o /tmp/install-bounty-copilot.sh && bash /tmp/install-bounty-copilot.sh
```

This installer creates a separate, unprivileged `bountycopilot` account, gives it **read-only** access to the scanner queue and a local restricted-permission copy of the existing Copilot OAuth login. The secret stays on the VPS and is **NOT pushed to GitHub**. It installs a systemd service/timer that checks the queue every 15 minutes and selects eligible, unassigned, **still-open** GitHub issue advertisements with an explicit amount of at least **10,000 sats**, skipping known testnet-only and heavily contested leads. It asks Copilot for an unverified task/risk assessment, saves the review under `/var/lib/bounty-copilot/reports`, and then stops. No open-source repository code is executed, no PR is submitted, and no patch is generated at this phase.

**Hard usage cap:** **one Copilot CLI AI request per UTC day**, even if there are many candidate issues. The Copilot CLI's `--max-ai-credits=30` argument is a per-session resource cap **not a monetary cap**. Keep Copilot Free and no payment method attached; monitor your included quota. The worker is configured to deny shell, writes, reads, URLs, and memory tools and to run under an unprivileged service account. Its AI results are unverified and must be checked by a person.

After installation (timer is enabled automatically):

```bash
systemctl list-timers bounty-copilot-bridge.timer --no-pager
journalctl -u bounty-copilot-bridge.service -n 30 --no-pager
ls -l /var/lib/bounty-copilot/reports
```

To stop ALL new AI requests immediately:

```bash
systemctl disable --now bounty-copilot-bridge.timer
```

**Security:** VPS root's already-authorized GitHub device-OAuth session is saved as plaintext on this headless host. The installer makes one other plaintext copy for the dedicated unprivileged service account (file mode `0600`, directory mode `0700`). Keep this VPS updated and access restricted. Do not paste tokens or config files into chats, logs or GitHub. Do not allow untrusted issue text to control shell commands. This is a capped review pipeline, not a guarantee of money or a complete autonomous coding agent.

## Automated Copilot source patch generation (new)

The real auto-coding worker is now implemented and unit-tested in `scripts/bounty_autocoder.py`. It upgrades the already-installed scanner-to-Copilot bridge and **generates local draft patches**, rather than just reviewing bounty ads. To activate it on the VPS, use the ONE command in [AUTOCODER.md](AUTOCODER.md). This step has not been performed on the VPS yet. Its initial release does not run outsider tests, submit PRs or guarantee payouts. It caps Copilot to one attempt/day and saves patch files for inspection.
