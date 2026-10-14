# Bounty Workbench — experimental cloud coding worker

**Status: draft worker uploaded; GitHub Copilot CLI is blocked by policy. Local-model runner proof of concept succeeded. No autonomous coding or submission is active.**

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

## Verified execution results — October 14, 2026

- **Copilot CLI GitHub Actions test**: did **NOT** work for the current account, returning `Access denied by policy settings` before generating any answer. [Failed run](https://github.com/Trelliz/bounty-workbench/actions/runs/38489608509). Do not assume activating Copilot Free allows Copilot API use inside Actions.
- **Zero-payment alternative**: a one-time test using the open-source `qwen2.5-coder:1.5b` model through Ollama on a standard public-repository GitHub Actions runner **succeeded** without GitHub Copilot or API credentials. The model generated a short `square(x)` function. [Successful run](https://github.com/Trelliz/bounty-workbench/actions/runs/38489761652).
- **Limitations**: The Ollama result is a proof of inference ONLY. It did not analyze a paid bounty, run a repository's tests, produce a reviewed patch, create a PR, or earn any sats. A 1.5B model may be inadequate for many real bugs.
- **Next build step**: safely turn the isolated local-model test into an opt-in read-only target checkout and artifact-producing patch worker, with validated candidate filtering and an explicit size/resource cap. Keep automatic external PR submission disabled.
- No payment method was added or needed for the open-source model test.

- **2026-10-14, second Copilot CLI attempt**: A user-created fine-grained PAT stored as the `COPILOT_PAT` GitHub Actions secret was confirmed valid by the GitHub `/user` API (HTTP 200). After the user added the `Copilot Requests` account permission, the isolated Actions smoke test still returned `Access denied by policy settings`. [Test run](https://github.com/Trelliz/bounty-workbench/actions/runs/38491565424). The personal account's Copilot CLI policy/entitlement remains unverified. Do not automatically start this workflow or infer paid access is required.
