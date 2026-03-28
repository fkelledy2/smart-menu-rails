---
name: Payments::IntentsController creates untracked Stripe PaymentIntents
description: The legacy IntentsController creates a Stripe PaymentIntent without creating a PaymentAttempt record or writing to the Ledger. When payment_intent.succeeded fires, the StripeIngestor can't find a PaymentAttempt — financial reconciliation has a gap.
type: project
---

`Payments::IntentsController#create` (`app/controllers/payments/intents_controller.rb`) calls `Stripe::PaymentIntent.create` directly, with only `order_id` in metadata (no `payment_attempt_id`). No `PaymentAttempt` is created and no `Payments::Ledger.append!` call is made.

When `payment_intent.succeeded` fires on the webhook:
- `StripeIngestor#payment_attempt_for_payload` looks for `payment_attempt_id` in metadata → nil
- Falls back to `PaymentAttempt.find_by(provider_payment_id:)` → nil (no PA was created)
- `Payments::Ledger.append!` is called with `entity_id: nil`
- The order IS still transitioned (because `order_id` is in metadata) but the PA record is missing

**Why:** This controller predates the `PaymentAttempt` / `Payments::Orchestrator` architecture and was never updated.

**How to apply:** Route Stripe intent creation through `Payments::Orchestrator#create_payment_attempt!` (which creates a PA and returns the client_secret), or at minimum create a `PaymentAttempt` record and include its ID in the Stripe metadata before creating the intent.
