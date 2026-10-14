# Bounty Workbench — experimental cloud coding worker

**Status: uploaded for review; AI execution runs ONLY when manually triggered.**

This repository contains a manual, opt-in GitHub Actions worker that can ask GitHub Copilot CLI to draft a code patch for an open public issue. It is separate from the user's SatGate project and from the Linux VPS bounty scanner.

## Important limitations

- **Not connected to the VPS scanner yet.** The scanner continues finding candidates independently; this worker does not auto-pick, solve, test, submit, or earn payouts.
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
