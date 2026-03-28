---
name: checkout_qr Stripe path missing PaymentAttempt
description: OrdrPaymentsController#checkout_qr creates a Stripe Checkout Session without a PaymentAttempt record — webhook reconciliation fails and Ledger entity_id is nil
type: project
---

`OrdrPaymentsController#checkout_qr` (app/controllers/ordr_payments_controller.rb) has two paths. The Square path correctly creates a `PaymentAttempt` before the adapter call. The Stripe path calls `Stripe::Checkout::Session.create` directly with metadata containing only `order_id` and `restaurant_id` — no `payment_attempt_id`.

When `checkout.session.completed` fires, `StripeIngestor#payment_attempt_for_payload` reads `md['payment_attempt_id']` (absent) and finds no matching record. The Ledger entry is written with `entity_id: nil` and the Ordr status is never advanced.

Fix: create a `PaymentAttempt` before the Stripe session, embed its ID in metadata, and attach the session ID back after creation.

**Why:** Square path was written correctly; the Stripe path was not updated to match the same pattern.

**How to apply:** Any time a Stripe Checkout Session is created, verify a `PaymentAttempt` record is created first and `payment_attempt_id` is in the metadata. Also check for orphan PaymentAttempt records (status: pending) if the Stripe session creation fails after the record is created.
