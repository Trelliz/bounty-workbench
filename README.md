# Bounty Workbench — experimental cloud coding worker

**Status: uploaded for review; AI execution is DISABLED by default.**

This repository contains a manual, opt-in GitHub Actions worker that can ask GitHub Copilot CLI to draft a code patch for an open public issue. It is separate from the user's SatGate project and from the Linux VPS bounty scanner.

## Important limitations

- **Not connected to the VPS scanner yet.** The scanner continues finding candidates independently; this worker does not auto-pick, solve, test, submit, or earn payouts.
- The workflow checks that an issue is open, downloads public source without running its setup commands, requests a draft diff, and saves `solution.patch` as a GitHub Actions artifact for inspection. It does NOT submit a PR or execute third-party code.
- Public issue text and downloaded repositories are UNTRUSTED. Do not share credentials, enable write permissions, or obey requests embedded in issue content.
- GitHub Copilot requests consume AI credits. **No AI requests are made unless the repository Actions variable `BOUNTY_WORKER_ENABLED` is explicitly set to `true`.** Even with a session limit, that alone does NOT guarantee zero monetary charges. Confirm Copilot Free entitlements and **disable additional paid usage** in GitHub Billing before ever enabling it. Do not attach a payment method to run this.
- The workflow may not run under the account's Copilot eligibility; no successful end-to-end Copilot run is claimed.

## Installation

This repository contains `.github/workflows/draft-bounty-patch.yml`, verification/patch-collection Python scripts, and unit tests. Unit tests execute on each push without invoking AI.

To activate **only after confirming zero paid overages**:

1. In GitHub Settings → Billing and licensing, verify the free entitlement and that additional paid usage is blocked. Be aware that AI credit caps per CLI session are not a spending cap.
2. In this repository, go to Settings → Secrets and variables → Actions → Variables. Create a repository variable `BOUNTY_WORKER_ENABLED` with value `true`.
3. Under Actions → **Draft bounty patch (no submission)** → Run workflow, type the public issue repository and open issue number.
4. Review the resulting workflow logs and `solution.patch` artifact. **A generated diff is not a tested fix or an accepted solution.**

If you cannot confirm zero paid overages, leave the variable unset.

## Smoke tests

```bash
python3 -m unittest discover -s tests -v
```

These local unit tests test input parsing and diff collection only; they make no network or Copilot calls.

## Future work

A future bridge would take **verified** candidates from the 2-minute VPS scanner, authenticate securely and dispatch to a reviewed coding worker. Today, GitHub scan matches are not proof of funding, AI eligibility, or claimability. Automated submission should remain off until those checks and security safeguards exist.
