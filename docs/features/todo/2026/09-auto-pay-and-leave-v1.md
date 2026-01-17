# Auto Pay & Leave (v1)

## Purpose
Close the dining loop so the customer can **pay and leave without waiting**, while keeping staff in control.

This feature is opt-in and must be explicit, safe, and observable.

## Current State (today)

- Order status includes `billrequested`, `paid`, `closed`.
- Stripe PaymentIntent creation exists.
- There is already an existing TODO feature doc for auto-pay-and-leave.

Cross references:

- `docs/features/todo/auto-pay-and-leave.md`
- `docs/features/todo/bill-splitting-feature-request.md`
- `docs/features/todo/stripe_restaurant_payments/README.md` (SaaS billing – separate)

Gaps:

- Stored credentials per diner are not implemented.
- Webhook-driven payment intent -> order state transition is not formalized.
- No “table freed automatically” mechanics.

## Scope (v1)

- Customer can opt-in to store a payment method (Stripe-managed) during the meal.
- Customer can opt-in to auto-pay.
- Trigger auto-pay when:
  - meal is marked complete, or
  - bill is requested (depending on rules)
- On success:
  - mark order paid
  - send receipt
  - mark table freed (if/when table state exists)

## Non-goals (v1)

- Forced auto-pay.
- Itemized bill splitting.
- Offline support.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Opt-in capture

- GIVEN a customer is viewing an active order
  WHEN they choose “Add payment method”
  THEN a Stripe-managed UI captures the payment method and the system stores only a provider reference (no PAN/PII).

### Arming auto-pay

- GIVEN a payment method is on file
  WHEN the customer enables auto-pay
  THEN the system records consent and shows a clear confirmation.

### Auto capture

- GIVEN auto-pay is enabled and an order becomes chargeable
  WHEN the trigger occurs (bill requested OR meal complete)
  THEN the system attempts a Stripe capture and records success/failure.

- GIVEN auto-pay capture succeeds
  WHEN confirmation is received
  THEN the order becomes `paid` and staff UI receives a real-time notification.

- GIVEN auto-pay capture fails
  WHEN failure is received
  THEN the order remains open and staff UI receives a real-time notification with a non-sensitive failure reason.

### Table freed

- GIVEN an order is successfully paid
  WHEN “auto pay & leave” is enabled
  THEN the table is marked available/freed according to the restaurant’s table management rules.

## Progress Checklist

- [ ] Reconcile this spec with `docs/features/todo/auto-pay-and-leave.md` (merge/keep both with links)
- [ ] Implement payment method on file (Stripe customer/payment method)
- [ ] Add consent + arming flags to order/participant
- [ ] Implement AutoPayCaptureJob
- [ ] Implement webhook mapping to update order state
- [ ] Add staff notifications (ActionCable)
- [ ] Add customer receipt delivery mechanism (email/SMS) (see Messaging feature)
- [ ] Add tests for:
  - [ ] consent persistence
  - [ ] capture success -> order paid
  - [ ] capture failure -> staff notified
