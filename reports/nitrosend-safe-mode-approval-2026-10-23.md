# Safe Mode MAP approval: verified owner decision (October 23, 2026)

- **Environment:** lAIboratory Nitrosend sender; GitHub Actions Ubuntu 24.04, Node v22.23.3, npm 10.9.9, `mailschema@0.3.2`. A single recipient was the owner's own address.
- **Workflow:** An API-key-originated campaign was held by Safe Mode; the owner provided the physical mailing address and approved the exact single-contact audience. Operator actions were needed for account setup, key handling and the review decision; the automated validation ran without further human steps.
- **Timing:** Safe Mode was already enabled when the campaign was created by 22:54 UTC. Owner decision: 23:40:58 UTC (under 47 minutes from campaign creation). The exact Safe Mode toggle timestamp was not logged, so its exact elapsed time cannot be established.
- **MIME extraction:** Saved the original approval email as `notes/approval-142.eml` in a private repository. Ran `npx --yes mailschema@0.3.2 message notes/approval-142.eml > description.json`.
- **Validation:** Downloaded `https://mailschema.org/artifacts/map-0.3/contracts/campaign-send-approval-0.1.json` as `contract.json`; ran `npx --yes mailschema@0.3.2 description description.json --contract contract.json`. Output: `Valid MAP 0.3 description urn:uuid:1795ddb6-5c62-5f07-a5ca-be325b4ee8c5`; description digest `sha-256:7df09d9f4e0fe94a878ecbec2e6b4c397540d0bcd3143c97008732d38f4680da`.
- **Term check:** Installed `mailschema@0.3.2` with npm; JavaScript imported `digest`, removed `terms.version`, recomputed `sha-256:9c539014eb26362e39758cff93143a0de0f8abd2210afd3eb90c8d588abfadc3`. Output: `MATCH: true`.
- **Decision:** Approved, because this campaign addressed only the owner. [Signed approval receipt](https://runx.ai/r/210b9ae6fab8313729469d0df9f872b2b6ef116da2208679c908576b617de23a). Approval is not proof of email delivery.
- **Slowdown and reproducible gap:** `npx --yes mailschema@0.3.2 --version` fails with `Unknown option '--version'`, despite the JavaScript README discussing a version flag. `npm view mailschema@0.3.2 version` returns `0.3.2`. Clarify version-reporting support in CLI docs.
- **Suggested improvement:** Publish a copy-paste MIME-extraction, contract-validation and `terms.version` digest example together.

## Delivery verification — 2026-10-24 00:04 UTC

- **Campaign:** Nitrosend `15167`, `lAIboratory owner-only Safe Mode review`.
- **Scheduled:** 2026-10-24 00:04:09 UTC; Nitrosend campaign status changed to `completed` by 00:04:12 UTC.
- **Provider delivery counters (queried 00:04:20 UTC):** `requested_recipients=1`, `recipients=1`, `sent=1`, `processed=1`, `failed=0`, `pending=0`, `progress_percent=100`.
- **Provider analytics (queried 00:04:26 UTC):** `email:sent=1`, `email:delivered=1`, `email:bounced=0`.
- **Independent inbox observation:** the account owner's Gmail received the non-test email with subject `Safe Mode approval test` at **2026-10-24 00:04:12 UTC**, matching the scheduled campaign. The private message ID and recipient address are intentionally omitted from this public report.
- **Interpretation:** this establishes that the approved one-recipient campaign actually sent and arrived in the owner's inbox. The approval receipt above proves the separate owner decision. Neither observation establishes Frantic bounty acceptance, payment, or a new signed send receipt for this campaign.
