# Private GitHub inbox for VPS bounty scanner

**Status:** publisher and tests are committed; publishing is **OFF**. No VPS commands
have been run, no GitHub token has been created or shared, and no messages
have been sent from the VPS.

## Purpose

The VPS runs a VPN as well as the bounty scanner. It must not be controlled by
an AI coding agent or run third-party project build scripts. The intended
communication direction is strictly **VPS scanner -> private GitHub Issues inbox**.

The helper in `scripts/publish_scanner_queue.py` reads the local scanner's
schema-1 JSON job records, checks the *public* GitHub issue is still open,
unassigned, and explicitly advertises at least 10,000 mainnet sats, then opens
a short issue in a **separate private repository**. This amount is only claimed
by the original issue: funding, payment, AI eligibility, and acceptance are
**not verified**. It does not clone repos, run code or Copilot, touch the VPN
configuration, submit PRs, or transmit scanner JSON or VPS details.

In each invocation it publishes no more than 3 leads, with a cap of 10 per UTC
day. It checks previously published inbox issue titles to avoid duplicates.
The command is dry-run unless `--publish` is explicitly specified. Publishing
is rejected for public inbox repositories and when executed as root.

## Setup prerequisites (one-time)

1. Create a NEW **private** GitHub repository, for example
   `Trelliz/bounty-inbox`, with GitHub Issues enabled. Keep the existing
   `Trelliz/bounty-workbench` public; it contains only source code and tests,
   **not** scanned lead data or secrets.
2. Ensure the ChatGPT GitHub connector is allowed to read this new private
   repository; otherwise the assistant cannot inspect the inbox automatically.
3. Make a **fine-grained personal access token** limited only to that private
   inbox repository, with **Issues: read/write** and inherent metadata-read
   permission. Do not grant Contents, Actions, Administration, or access to
   other repositories. Prefer a short expiry. Do not paste or send that token
   to ChatGPT, GitHub issues, or repository source.
4. The token must eventually be stored only on the VPS in a Linux file owned
   by `bountyhunter` with permission `0600`. The publisher must execute as
   `bountyhunter` (not root) so it can read scanner-owned queue entries
   without accessing VPN files.

When the private repository exists, request help with **one-time VPS
installation**. This code is inert until a user deliberately provisions the
minimal token and invokes the publisher. It is reasonable to test
`--dry-run` first. Do not pipe arbitrary unreviewed scripts to `bash`.

## Example (after the private repo and least-privilege account are ready)

Install *both* scripts in the same directory:
`scripts/bounty_copilot_bridge.py` and `scripts/publish_scanner_queue.py`.
The publisher imports the original bridge's safe queue reader and conservative
candidate qualification functions.

```bash
# Dry-run: no private token and no GitHub changes
python3 publish_scanner_queue.py --destination Trelliz/bounty-inbox

# After you have stored the private Issues-only PAT in a mode-0600 file owned
# by bountyhunter, explicitly permit publishing:
python3 publish_scanner_queue.py --destination Trelliz/bounty-inbox \
  --token-file /var/lib/btc-bounty-hunter/private-inbox-token --publish
```

The actual service/timer is **not installed** by this commit. First verify the
dry-run and the private inbox repository access. Any automated schedule should
run under the unprivileged scanner account, with strict filesystem protections,
a limited network allowance, and no new shell or code execution privileges.

## Safety and current limitations

- Private GitHub issue inbox is still a cloud copy of **public** GitHub issue
  links, so only these links and advertised integer amounts are uploaded.
- The scanner itself may miss bounties or surface spam and misleading rewards.
- The importer intentionally excludes the 777-sat Amethyst issue as too small.
- GitHub API limits, token expiry, and the 500-issue remote deduplication limit
  can stop imports. Failures should not silently publish to a public repo.
- For candidate filtering, public issue text is treated as untrusted data.
- No automated external PR submissions or spending are enabled.

Run all repository unit tests with `python3 -m unittest discover -s tests -v`.
