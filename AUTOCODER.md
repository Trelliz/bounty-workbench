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

## Important limitations and protection

- **No third-party code execution**, package installation, project tests, GitHub PR creation, Git pushes or automatic payments.
- Static validations: git patch applicability and whitespace; parse Python files with Python's AST. These **do not prove the code works**.
- Maximum **one Copilot CLI invocation each UTC day** across the earlier triage and new drafting service. Copilot Free allowance is finite. No payment method is required, but the 30 AI credit CLI cap is **not** a monetary spending limit.
- The project, issue, claimed reward, eligibility and AI-generated patch remain **untrusted and unverified**. Do not assume a bounty is funded or pay-to-claim scams are legitimate.
- If no eligible lead appears, it waits without invoking Copilot.
- This uses the OAuth session copied to the restricted service account by the previous installer. Treat the VPS as sensitive because the OAuth credential is stored in a plaintext file there. Protect SSH access; never paste credentials into chat.
- A human should review each patch and the bounty's rules before any contribution is submitted.

The code is in `scripts/bounty_autocoder.py`, with tests in `tests/test_bounty_autocoder.py`. Standard GitHub Actions CI tests run without any AI requests or secrets.
