# Nitrosend Safe Mode: owner-reviewed single-recipient send

This is a factual, timestamped account of a first-person email approval workflow. It records what was observed, not a claim that an email was delivered.

- **Environment:** Nitrosend AI-native email, lAIboratory sender account.
- **Scope:** one self-controlled recipient on a single-contact list; no third-party audience.
- **Campaign reference:** `15167`, "lAIboratory owner-only Safe Mode review".
- **Review:** a Safe Mode campaign send was placed on hold for the account owner's approval.
- **Approval:** the account owner approved the exact one-recipient send. Nitrosend issued a signed approval-decision receipt at **2026-10-23 23:40 UTC**:
  [Nitrosend signed Safe Mode approval receipt](https://runx.ai/r/210b9ae6fab8313729469d0df9f872b2b6ef116da2208679c908576b617de23a).
- **Scheduling:** at the last account read, the campaign status was `scheduled`, with intended send time **2026-10-24 00:04:09 UTC** (03:04:09 Moscow time).
- **Observed outcome at this point:** approval received; the actual campaign send had **not yet started**. Recipient delivery is **not yet established**.

## Reproducible review approach

1. Prepare a single-recipient email campaign on a sender account you control.
2. Request Safe Mode review and inspect the pending approval decision.
3. Have the actual account owner review the content and audience; never bypass owner approval.
4. Record the signed decision receipt and its UTC timestamp.
5. Separately inspect campaign delivery totals after its scheduled time. Do not infer delivery from approval alone.
6. If it sends, document the actual status and any separate verifiable send receipt; otherwise report the true blocker.

## Limitations

The signed URL above is evidence of the **approval decision**, not proof of provider delivery or a payout. No credentials, recipient email address, mailing address, or private message content are included here.
