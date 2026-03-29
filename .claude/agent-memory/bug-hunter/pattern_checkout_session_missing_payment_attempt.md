---
name: checkout_session non-split path creates no PaymentAttempt
description: OrdrPaymentsController#create_stripe_checkout did not create a PaymentAttempt record when split_payment was nil — webhook reconciliation and Ledger tracking failed for standard checkout
type: feedback
---

`create_stripe_checkout` called `split_payment&.update!(...)` meaning when `split_payment` is nil (the normal non-split checkout path), no `PaymentAttempt` was created. The Stripe webhook ingestor looks up `payment_attempt_id` from Stripe metadata but found nothing — `entity_id` was nil in the Ledger and the order was never transitioned to paid.

The fix creates a `PaymentAttempt` with a stable idempotency key (`checkout_session:ordr:<id>` or `checkout_session:split:<id>`) before creating the Stripe session, then stores the session id in `provider_payment_id`. The `payment_attempt_id` is also stamped into the Stripe metadata so the webhook can resolve it directly.

**Why:** The split path has its own `OrdrSplitPayment` record and didn't need a `PaymentAttempt`, but the non-split path had no equivalent tracking record.

**How to apply:** Any code path that creates a Stripe/Square session or intent must create a `PaymentAttempt` first. Check for `payment_attempt_id` in Stripe metadata to verify — its absence means the path is untracked.
