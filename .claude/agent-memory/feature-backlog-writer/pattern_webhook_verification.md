---
name: Webhook verification service pattern
description: Inbound webhooks always verified via a dedicated service object using HMAC-SHA256 before any processing
type: project
---

Established pattern (used in both Strikepay and CRM/Calendly specs): every inbound webhook endpoint has a paired `*WebhookVerifier` service in `app/services/` that:

1. Reads the signature header
2. Recomputes HMAC-SHA256 against the raw request body using a secret stored in Rails credentials
3. Raises a typed error (e.g. `Crm::WebhookVerificationError`) on failure

The controller responds `401` with no body on verification failure. It then immediately enqueues a background job and responds `200` — no synchronous processing in the controller.

**Why:** Webhook endpoints skip session auth; HMAC verification is the only authentication layer. Doing it in a service object makes it independently testable.

**How to apply:** Any future webhook integration spec should follow this pattern. Never verify inline in the controller. Always raise a typed error, not a generic `StandardError`.
