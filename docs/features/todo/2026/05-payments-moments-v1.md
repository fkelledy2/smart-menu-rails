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
  - QR → **Stripe Checkout Session**
- Implement partial payment support (v1): **even split only** (via dedicated split payment records).

## Decisions locked for v1

- Stripe integration: **Checkout Session** (not Payment Element).
- Split payments data model: **Option B** (dedicated model/records per participant payment).
- “No opened items” means: there are **no** `ordritems` where `ordritems.status == 'opened'`.

## Canonical payment UX states (derived)

These are UI states (not necessarily DB columns). The UI should derive them primarily from `ordr.status` and split-payment state.

- `pay_hidden`
  - Order is not in `billrequested`.
- `pay_available`
  - Order is `billrequested` and not fully paid.
- `pay_in_progress`
  - A Checkout Session has been created for the current participant/device and is pending.
- `pay_succeeded`
  - Participant payment succeeded (split flow) OR the order is fully paid.
- `pay_locked`
  - Order is `closed` (or otherwise no longer payable).

## Proposed server surfaces (v1)

The intent is to keep this small and Stripe-led.

- `POST /ordrs/:id/request_bill`
  - Transitions order to `billrequested` (if allowed).
- `POST /ordrs/:id/payments/checkout_session`
  - Creates a Stripe Checkout Session for:
    - full amount (non-split), OR
    - the participant share (split)
  - Returns `checkout_url`.
- `POST /payments/webhooks/stripe`
  - Receives Checkout completion events and updates:
    - split-payment record(s)
    - order `paid` when fully settled

## Split payments (even split only) – Option B

### Model sketch

Create a dedicated record per participant share (name TBD, e.g. `OrdrSplitPayment`).

Minimum fields:

- `ordr_id`
- `ordr_participant_id` (nullable if you choose “split by number” later)
- `amount_cents`
- `currency`
- `status` (e.g. `pending`, `requires_payment`, `succeeded`, `failed`, `canceled`)
- Stripe references:
  - `stripe_checkout_session_id`
  - `stripe_payment_intent_id` (if available from session)

### Settlement rule

- Order becomes `paid` when:
  - all split payment records are `succeeded`, OR
  - the non-split payment succeeds.

### Rounding rule (v1)

- Compute `N` shares.
- Use integer cents.
- Allocate remainder cents by adding +1 cent to the first K participants.

## Non-goals (v1)

- Itemized splitting.
- Stored credentials / auto-pay (separate feature: Auto-Pay-and-Leave).
- POS integration.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Request bill moment

- GIVEN an order with at least one ordered item and no `ordritems` where `ordritems.status == 'opened'`
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
- [ ] Add Stripe integration for chosen flow (Checkout Session)
- [ ] Add payment confirmation handling (success/failure)
- [ ] Add even-split data model and UI (Option B split payment records; reuse/align with bill splitting doc)
- [ ] Add staff visibility of split payment state
- [ ] Add tests:
  - [ ] request bill transition => pay visible
  - [ ] successful payment => order becomes paid
  - [ ] even split calculations and rounding
