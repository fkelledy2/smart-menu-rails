# Voice Ordering (v1 – Constrained)

## Purpose
Ship a **hard-whitelist** voice intent system that:

- Saves real seconds in service
- Produces predictable outcomes
- Is always reversible within a short window
- Always emits canonical order state mutations

## Current State (today)

- Smartmenu customer voice commands exist and are documented.
- The implementation supports voice capture, async processing, intent parsing, and action execution in the Smartmenu context.

Cross references:

- `docs/features/in-progress/voice-menus.md`
- `docs/features/todo/voiceApp.md`

Gaps vs this spec:

- Intent set is broader / less formally constrained than the roadmap.
- There is no explicit system-wide “confidence < threshold => reject” rule enforced everywhere.
- There is no unified “undo window” across voice actions.
- Voice actions are not yet formally bound to a canonical OrderEvent stream (future: `OrderEvent`).

## Scope (v1)

### Supported intents (hard whitelist)

- `add_same_item`
- `undo_last_action`
- `request_bill`
- `pay_now`
- `order_ready` (staff)
- `delay_order_x` (staff)

### Execution rules

- Confidence `< 0.85` => reject with a clear UI response (no mutation).
- Always emit a canonical state mutation (future: `OrderEvent`, currently: at least consistent `Ordraction` + state transition).
- Always show confirmation.
- Undo window: 5–10 seconds.

## Non-goals (v1)

- No free-text ordering.
- No menu discovery by voice.
- No “ask anything” conversational layer.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Confidence gating

- GIVEN a voice transcript classified as one of the whitelisted intents
  WHEN the confidence is `< 0.85`
  THEN the system does not mutate the order and returns a rejection response with a visual fallback.

### add_same_item

- GIVEN a customer has an active order and has previously added an item
  WHEN the customer says “same again” and the system resolves intent `add_same_item` with confidence `>= 0.85`
  THEN the system adds `qty=1` of the most recently added item and returns a confirmation.

- GIVEN `add_same_item` is executed
  WHEN the mutation succeeds
  THEN a canonical mutation record is written (future: `OrderEvent.item_added`).

### undo_last_action

- GIVEN a voice action mutated the order within the last 10 seconds
  WHEN the customer says “undo” and intent is `undo_last_action`
  THEN the system reverts the last mutation and returns confirmation.

### request_bill

- GIVEN an order has no `opened` items and has at least one ordered item
  WHEN a customer says “can we get the bill” and intent is `request_bill`
  THEN the system transitions the order to `billrequested` and returns confirmation.

### pay_now

- GIVEN an order is in `billrequested`
  WHEN the customer says “pay now” and intent is `pay_now`
  THEN the system presents the payment UX entry point and records the intent.

### staff intents

- GIVEN a staff user is authenticated and scoped to the restaurant
  WHEN staff says “order ready” with a table/order identifier
  THEN the order transitions to `ready` and the kitchen/customer views update in real time.

- GIVEN staff says “delay order 10 minutes”
  WHEN intent is `delay_order_x`
  THEN a delay marker is recorded and visible in operational UI.

## Progress Checklist

- [ ] Define canonical intent whitelist (single source)
- [ ] Implement confidence gating consistently
- [ ] Implement undo window + rollback strategy
- [ ] Add staff-authenticated voice endpoints (separate from customer)
- [ ] Ensure each voice intent emits canonical order mutation records
- [ ] Add integration tests for each intent + rejection path
- [ ] Document “Do Not Build” rules in this feature scope
