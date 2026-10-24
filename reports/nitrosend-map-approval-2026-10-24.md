# lAIboratory — owner-only Safe Mode MAP approval test

- **Setup:** Termux Python 3.13.13; Node v26.3.1; `npm install --no-audit --no-fund --prefix <temporary-directory> mailschema@0.3.2`. ChatGPT's connected Nitrosend MCP created a contact, owner-only list 12777 and campaign 15167; a local API-key-authenticated Python script made the scheduling request. API key was entered locally, not disclosed.
- **Commands:** `GET /v1/my/account`; `GET /v1/my/campaigns/15167`; `GET /v1/my/templates/24276`; `POST /v1/my/campaigns/15167/send` with `expected_campaign_updated_at`, `template_if_version`, `deliver_at=2026-10-24T00:04:09Z`. Safe Mode held the request; no other recipients were targeted.
- **Timing:** Safe Mode enabled approximately 23:03 UTC; owner approved at 23:40:58 UTC on October 23, 2026 (~38 minutes). The approval email arrived 23:39:15 UTC.
- **MAP extraction:** Original email's quoted-printable `application/ld+json` part with `profile=https://mailschema.org/profiles/map/0.3` was decoded, with the resulting JSON bytes retained unchanged.
- **Validation:** `mailschema description description.json --contract campaign-send-approval-0.1.json` (package v0.3.2) printed: `Valid MAP 0.3 description urn:uuid:1795ddb6-5c62-5f07-a5ca-be325b4ee8c5 | sha-256:7df09d9f4e0fe94a878ecbec2e6b4c397540d0bcd3143c97008732d38f4680da`.
- **Digest:** Node script imported `digest` from `mailschema`, removed `terms.version`, and computed `sha-256:9c539014eb26362e39758cff93143a0de0f8abd2210afd3eb90c8d588abfadc3`; matches the email's `terms.version` exactly.
- **Decision:** Owner **approved** the exact one-recipient, scheduled campaign after checking the MAP review page. Nitrosend published an authentic decision receipt at 23:40:59 UTC.
- **Slowest step / finding:** An initial homemade REST parser rejected the nested campaign response; adjusting it resolved the problem. No Nitrosend implementation bug confirmed after inspecting account, campaign and held-send states. Better full example responses for headless Safe Mode approval would simplify setup.
- **Change:** Provide a short end-to-end API-key Safe Mode + MAP verification example in the documentation.
