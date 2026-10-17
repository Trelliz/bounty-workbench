# Copilot automatic patch drafter (VPS)

**Status:** Implementation committed and offline tests pass. **It is not installed on the VPS until the owner runs the one-time upgrade.** We have not yet verified a real Copilot-generated patch.

## Install once

Open Termius on the VPS that already runs the BTC scanner and has the working device-authorized Copilot CLI, then paste:

```bash
curl -fsSL https://raw.githubusercontent.com/Trelliz/bounty-workbench/main/scripts/install_bounty_autocoder.sh -o /tmp/install-autocoder.sh && bash /tmp/install-autocoder.sh
```

The existing 15-minute bridge timer is upgraded **in place**. It no longer spends credits on triage: instead, it searches the scanner's queue for open, unassigned bounty issues with explicit advertised rewards of >= 10,000 sats and public repositories smaller than ~12 MB. On an eligible issue, it clones only the public source, selects small relevant tracked code files, asks the **already authenticated GitHub Copilot CLI** for a unified source patch, checks that the patch touches only those files and can be applied, and saves a diff and result JSON.

Results appear in `/var/lib/bounty-copilot/code-reports/<owner>__<repo>__<issue>/solution.patch` and `result.json`. Inspect progress with:

```bash
journalctl -u bounty-copilot-bridge.service -n 40 --no-pager
find /var/lib/bounty-copilot/code-reports -name result.json
```

Stop the timer immediately with `systemctl disable --now bounty-copilot-bridge.timer`.

## October 17, 2026: false-positive filtering on an existing VPS

Two private inbox leads were mistakenly sourced from Bitcoin **mining block subsidies**
(3.125 BTC) rather than payments to developers. They have been closed in the private
inbox. The shared Python qualification function now requires an explicit
contributor-payment context on the same or immediately preceding line and ignores
block-reward, lottery and jackpot amounts. Offline regression tests pass.

**Updating GitHub source alone does NOT update the existing VPS.** If the old bridge
or inbox publisher is installed, update only those filters using this immutable,
reviewable helper from Termius (root shell):

```bash
curl -fsSL https://raw.githubusercontent.com/Trelliz/bounty-workbench/cc0bf180c6117da5d447f3751d7b94813bf0e3b4/scripts/upgrade_bounty_filters.sh -o /tmp/upgrade-bounty-filters.sh && bash /tmp/upgrade-bounty-filters.sh
```

This changes only already-installed Python bridge/publisher files and keeps OAuth,
PAT, VPN, systemd configuration, job queue and billing untouched. It does **not**
deploy the auto-coding worker if that separate step has not been performed.
The existing timers pick up the corrected filters on their next invocation.

The correction remains heuristic, not an escrow or eligibility check. Search for
funded bounties on purpose-built Bitcoin/Lightning bounty platforms and check
the live funding/claim conditions and allowed AI usage before submitting work.
Do not run unknown third-party project code on the VPN VPS.

## Important limitations and protection

- **No third-party code execution**, package installation, project tests, GitHub PR creation, Git pushes or automatic payments.
- Static validations: git patch applicability and whitespace; parse Python files with Python's AST. These **do not prove the code works**.
- Maximum **one Copilot CLI invocation each UTC day** across the earlier triage and new drafting service. Copilot Free allowance is finite. No payment method is required, but the 30 AI credit CLI cap is **not** a monetary spending limit.
- The project, issue, claimed reward, eligibility and AI-generated patch remain **untrusted and unverified**. Do not assume a bounty is funded or pay-to-claim scams are legitimate.
- If no eligible lead appears, it waits without invoking Copilot.
- This uses the OAuth session copied to the restricted service account by the previous installer. Treat the VPS as sensitive because the OAuth credential is stored in a plaintext file there. Protect SSH access; never paste credentials into chat.
- A human should review each patch and the bounty's rules before any contribution is submitted.

The code is in `scripts/bounty_autocoder.py`, with tests in `tests/test_bounty_autocoder.py`. Standard GitHub Actions CI tests run without any AI requests or secrets.
