# Payments Moments (Stripe-led) (v1)

## Purpose
Make payment a **moment, not a hunt**.

Key principle:

- The system owns **when** payment happens (state + UX triggers), not necessarily **how** (Stripe implementation details can evolve).

## Current State (today)

- Stripe is used for end-customer payments via `Payments::IntentsController` (PaymentIntent creation).
- Order lifecycle includes `billrequested`, `paid`, `closed` states.
- There is existing work scoped for auto-pay and bill splitting.

Cross references:

- `docs/features/todo/stripe_restaurant_payments/README.md` (note: this is SaaS billing; separate)
- `docs/features/todo/bill-splitting-feature-request.md`
- `docs/features/todo/auto-pay-and-leave.md`

Gaps:

- No explicit “request bill” UX moment definition across surfaces.
- Partial payments are not implemented.
- “Pay at table” QR-to-checkout flow may exist partially, but not formalized as an end-to-end product moment.

## Scope (v1)

- Standardize the **bill requested** transition as the trigger to show payment UI.
- Implement pay-at-table flow:
  - QR → Stripe Checkout or Payment Element
- Implement partial payment support (v1): **even split only**.

## Non-goals (v1)

- Itemized splitting.
- Stored credentials / auto-pay (separate feature: Auto-Pay-and-Leave).
- POS integration.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Request bill moment

- GIVEN an order with at least one ordered item and no opened items
  WHEN the customer triggers “Request Bill”
  THEN the order transitions to `billrequested` and the UI exposes payment options.

- GIVEN an order is in `billrequested`
  WHEN the customer reloads the smart menu
  THEN `payVisible=true` (or equivalent) is true and payment entry remains visible.

### Pay at table (Stripe)

- GIVEN an order is in `billrequested`
  WHEN the customer chooses “Pay now”
  THEN the system creates a Stripe PaymentIntent (or Checkout Session) and returns a client secret/session URL.

- GIVEN a Stripe payment succeeds
  WHEN confirmation is received
  THEN the order transitions to `paid` and the kitchen/staff/customer views update in real time.

### Even split (v1)

- GIVEN an order in `billrequested` with N participants
  WHEN the customer selects “Split evenly”
  THEN the system computes N equal amounts (with rounding rules) and generates a payment flow per participant.

- GIVEN some participant payments succeed and others are pending
  WHEN staff views the order
  THEN staff can see partial settlement status (e.g., `paid_portion`, `remaining`).

## Progress Checklist

- [ ] Define canonical payment UX states tied to order status (`billrequested` as entry)
- [ ] Implement pay-at-table UX entry point and server endpoints
- [ ] Add Stripe integration for chosen flow (Payment Element / Checkout)
- [ ] Add payment confirmation handling (success/failure)
- [ ] Add even-split data model and UI (reuse/align with bill splitting doc)
- [ ] Add staff visibility of split payment state
- [ ] Add tests:
  - [ ] request bill transition => pay visible
  - [ ] successful payment => order becomes paid
  - [ ] even split calculations and rounding
