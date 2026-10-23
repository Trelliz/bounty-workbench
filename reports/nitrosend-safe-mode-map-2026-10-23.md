# Nitrosend Safe Mode / Mail Action Protocol validation — 2026-10-23

- **Runtime / tools:** ChatGPT Android 1.2026.265, GPT-6, Nitrosend MCP (server build not exposed); GitHub Actions Ubuntu runner, Node v22.23.3, npm 10.9.9, `mailschema@0.3.2`.
- **Setup:** Used the existing Nitrosend account and hosted sender; Safe Mode was enabled. Agent prepared a campaign to a contact list containing only the owner's email address, scheduled for 2026-10-24 00:04:09 UTC, through the API-key-backed account workflow. One approval request arrived by email.
- **Message extraction:** From the exact original `multipart/related` approval message, ran `npx --yes mailschema@0.3.2 message notes/approval-142.eml > description.json` in a private GitHub Actions job. It reported: `Valid MAP 0.3 description urn:uuid:1795ddb6-5c62-5f07-a5ca-be325b4ee8c5`.
- **Contract:** Fetched the unmodified `campaign-send-approval-0.1.json` from `https://mailschema.org/artifacts/map-0.3/contracts/`; ran `npx --yes mailschema@0.3.2 description description.json --contract contract.json`. Output: `Valid MAP 0.3 description urn:uuid:1795ddb6-5c62-5f07-a5ca-be325b4ee8c5`.
- **Version binding:** In Node imported `digest` from `mailschema`, parsed `description.json`, deleted `description.terms.version` and computed `digest(description)`. Recorded and recomputed: `sha-256:9c539014eb26362e39758cff93143a0de0f8abd2210afd3eb90c8d588abfadc3`. **MATCH: true**.
- **Decision / timing:** Owner **approved** the owner-only, one-recipient send. Request issued 23:39:14 UTC; decision 23:40:58 UTC (**1 minute 44 seconds** after request). Exact Safe Mode activation time was not preserved, so total activation-to-decision minutes cannot be verified.
- **Slowest step:** Coordinating the owner review / extracting the machine-readable email part; no package validation failure. **Documentation improvement:** include a quoted-printable MAP extraction example for Gmail raw MIME. No additional product defect established.

No API keys or tokens were published.
