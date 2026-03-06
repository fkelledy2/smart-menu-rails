# Unified Order State Engine (v1)

## Purpose
Make **one live, authoritative dining state** the foundation for:

- Customer ordering UX
- Staff + kitchen operational truth
- Voice actions (customer + staff)
- Payment state transitions
- Partner integrations (event-driven)

This spec introduces an **append-only canonical event log** and a **deterministic reducer** that produces a materialized “current state”.

## Current State (today)

- The system already has **order lifecycle state** in `Ordr` (AASM + enum): `opened → ordered → preparing → ready → delivered → billrequested → paid → closed`.
- The system records some user actions via **`Ordraction`** (e.g., `additem`, `removeitem`, `requestbill`).
- The system already has real-time broadcasting for orders and kitchen updates.

Gaps:

- `Ordraction` is not a **general canonical event log** (limited action types, not strictly append-only for all state mutations).
- There is no deterministic reducer / projection layer that can rebuild state from events.
- Not all state mutations are guaranteed to emit a single canonical record.

Cross references:

- `docs/features/done/REALTIME_IMPLEMENTATION_STATUS.md`
- `docs/features/done/KITCHEN_DASHBOARD_UI.md`

## Scope (v1)

- Introduce `OrderEvent` as canonical event stream for dining state.
- Ensure **every order mutation** emits exactly one canonical `OrderEvent`.
- Provide deterministic reducer logic that can rebuild state.
- Provide at least one projection path:
  - `Ordr` + `Ordritem` continue to exist as the “materialized state”, but are now **derived** and kept consistent via event-driven projection.

## Non-goals (v1)

- Complex conflict-free replicated data types (CRDTs).
- Partner integrations.
- AI-driven automation.
- Multi-order/table merge/split.

## Data Model (proposed)

### `OrderEvent`

Fields (minimum viable):

- `id`
- `ordr_id` (required)
- `sequence` (required, monotonic per `ordr_id`)
- `event_type` (e.g. `item_added`, `item_removed`, `status_changed`, `bill_requested`, `paid`)
- `entity_type` (`order`, `item`, `participant`, `payment`)
- `entity_id` (nullable, depending on entity)
- `payload` (JSON: qty, menuitem_id, modifiers, delay_minutes, etc.)
- `source` (`guest`, `staff`, `voice`, `system`, `webhook`)
- `idempotency_key` (nullable but recommended)
- `occurred_at` (recommended; when the action actually happened)
- `created_at`

Indexes / constraints (recommended for v1):

- Unique: (`ordr_id`, `sequence`) to guarantee deterministic replay ordering.
- Unique (partial): (`ordr_id`, `idempotency_key`) WHERE `idempotency_key IS NOT NULL` to dedupe voice + webhook retries.
- Index: (`ordr_id`, `created_at`, `id`) for debugging.

Sequence allocation (v1):

- Determinism should not rely on timestamps.
- Allocate `sequence` inside the same DB transaction as the mutation using a lock on `Ordr` (or an equivalent per-order lock) so that events are strictly ordered per order.

## Event taxonomy (v1 whitelist)

Item events:

- `item_added` (`entity_type=item`)
  - payload: `menuitem_id`, `qty`, optional: `notes`, `modifiers`, `price_cents`, `currency`.
- `item_removed` (`entity_type=item`)
  - payload: `ordritem_id` and `line_key`.

Order status events:

- `status_changed` (`entity_type=order`)
  - payload: `from`, `to`, optional: `reason`.
- `bill_requested` (`entity_type=order`)
  - payload: optional `reason`.
- `paid` (`entity_type=payment`)
  - payload: `provider`, `external_ref`, optional: `amount_cents`, `currency`.
- `closed` (`entity_type=order`)
  - payload: optional `reason`.

Participation events (optional v1):

- `participant_joined` (`entity_type=participant`)
  - payload: `role`, `sessionid`, optional `employee_id`.

## Reducer (v1)

Introduce a deterministic reducer that can replay an `OrderEvent` stream into a computed state:

- Input ordering is `ORDER BY sequence ASC`.
- Reducer must be pure/deterministic given the same event stream.
- Unknown `event_type` must not corrupt state; reducer should report unsupported events.

Suggested shape of computed state (v1):

- `status`
- `items` (keyed by `ordritem_id` for v1)
- `totals` (optional; can remain computed by existing `Ordr` methods initially)

## Projection (v1)

Projection path requirement:

- `Ordr` + `Ordritem` continue to exist as the “materialized state”, but are now **derived** and kept consistent via event-driven projection.

Projection guarantees:

- Every successful mutation emits exactly one `OrderEvent`.
- Projections apply events in order and update `Ordr`/`Ordritem` accordingly.

Recommended projection metadata:

- Add `ordrs.last_projected_order_event_sequence` (default 0).

Processing model (v1):

- A background job (Sidekiq) replays events for a single order in strict sequence order.
- Projection must be idempotent and safe to retry.

## Integration points (current code mapping)

Initial emission targets (v1 vertical slice order):

1. `OrdritemsController#create` and `OrdritemsController#destroy`
   - Today these already create `Ordraction` records and broadcast updates.
   - Add `OrderEvent` emission alongside existing behavior.

2. Order status transitions (AASM events in `Ordr`)
   - Emit `status_changed` / `bill_requested` / `closed` as applicable wherever transitions are triggered.
   - Keep existing kitchen broadcasts initially; later drive broadcasts from projected/materialized updates.

3. Payment webhook success path
   - Emit `paid` with `source=webhook` and an idempotency key.

Additional v1 operational/debug endpoints:

- `GET /restaurants/:restaurant_id/ordrs/:id/events` (debug: event stream + cursor)
- `POST /payments/webhooks/stripe` (Stripe webhook: `payment_intent.succeeded`)

## Integration points (detailed producers / consumers)

### State producers (server-side mutation entry points)

These are the current code paths that mutate `Ordr` / `Ordritem` (and therefore must emit exactly one `OrderEvent` on success).

- `app/controllers/ordritems_controller.rb`
  - `create` (adds an item)
    - v1: event-first emit `item_added` with a stable per-item `line_key`, then project immediately.
  - `destroy` (removes an item)
    - v1: event-first emit `item_removed` (by `line_key`) then project immediately.
    - v1 note: projector marks items `removed` (does not hard-delete) to preserve FK integrity and audit.
  - `update` (edits an item)
    - v1: when `status` is set to `removed`, treat as an `item_removed` event (this is what voice uses).
    - v1 note: other edits remain non-goal for v1 unless promoted later.

- `app/controllers/ordrs_controller.rb`
  - `create` (creates an order)
    - v1: optional event `order_opened` (or omit in v1 and treat order creation as out-of-band initialization).
  - `update`
    - Today: changes `status`, promotes items on submit (`OrdrStationTicketService.submit_unsubmitted_items!`), recalculates totals, broadcasts.
    - v1: emit `status_changed` for any status transition.
    - v1: canonical approach is `status_changed` with `{to: billrequested}` (no separate `bill_requested` emission).

- `app/channels/kitchen_channel.rb`
  - `receive` → `handle_status_update`
    - Today: `order.update(status: data['new_status'])` then broadcasts status change.
    - v1: treat as staff-driven status transition and emit `status_changed` with `source=staff`.

- `app/controllers/payments/base_controller.rb`
  - `create_payment_link`
    - Today: writes `Ordr.paymentlink`.
    - v1: optional event `payment_link_created` (non-goal unless we need auditing).

- `app/controllers/payments/intents_controller.rb`
  - `create`
    - Today: creates a Stripe PaymentIntent with metadata referencing `order_id`.
    - v1: no state change; do not emit `paid` here.

- `app/controllers/api/v1/orders_controller.rb`
  - `create` / `update`
    - v1: must also emit canonical events (at minimum `item_added` / `status_changed`) if this API is considered live.
    - v1: if the API is legacy/unused, document as out-of-scope and plan a later migration.

- Voice command pipeline
  - `app/controllers/smartmenus_voice_commands_controller.rb` creates `VoiceCommand`.
  - `app/services/voice_command_intent_service.rb` parses intents like `add_item`, `remove_item`, `request_bill`, `submit_order`, `close_order`.
  - v1: voice UI triggers the existing mutation endpoints and tags requests with `X-Order-Source: voice` so emitted events use `source=voice`.

### State consumers (client-side / realtime)

These are the current consumers of “authoritative state”. In v1, they should continue consuming `SmartmenuState` / materialized `Ordr` until projections are enabled.

- ActionCable channels
  - `app/channels/ordr_channel.rb` streams `ordr_<order_id|slug>_channel`.
  - `app/channels/kitchen_channel.rb` streams `kitchen_<restaurant_id>`.

- Broadcast producers (server)
  - `Ordr` model callbacks broadcast kitchen updates via `KitchenBroadcastService`.
  - `OrdrsController#broadcast_state` and `OrdritemsController#broadcast_state` broadcast JSON state built by `SmartmenuState.for_context(...)`.

- Browser state store
  - `app/javascript/channels/ordr_channel.js` receives `{ state: payload }` and dispatches `document` event `state:update`.
  - `app/javascript/controllers/state_controller.js` listens for `state:update` and maintains `window.__SM_STATE`.
  - View controllers (e.g. `order_header_controller.js`) render UI based on `window.__SM_STATE`.
  - `app/javascript/ordr_commons.js` also refetches `/smartmenus/:slug.json` after mutations for safety.

### Mutation → canonical `OrderEvent` mapping (v1)

| Existing mutation path | Canonical event_type | entity_type | source | Notes |
| --- | --- | --- | --- | --- |
| `OrdritemsController#create` | `item_added` | `item` | `guest` or `staff` | payload includes `menuitem_id`, `qty` (assume 1 unless provided). |
| `OrdritemsController#destroy` | `item_removed` | `item` | `guest` or `staff` | payload includes `ordritem_id`. |
| `OrdrsController#update` (status change) | `status_changed` | `order` | `guest` or `staff` | payload includes `from`, `to`. |
| `OrdrsController#update` (to billrequested) | `bill_requested` OR `status_changed` | `order` | `guest` | choose one canonical approach and enforce it consistently. |
| `KitchenChannel#handle_status_update` | `status_changed` | `order` | `staff` | Treat as staff action. |
| Payment success (webhook) | `paid` | `payment` | `webhook` | idempotency key required (provider ref). |
| Voice execution (add/remove/bill/submit/close) | same as above | varies | `voice` | idempotency key required (voice command id). |

## Implementation checklist (by file) for v1

Event emission (Phase 1):

- [ ] `app/controllers/ordritems_controller.rb`
  - [ ] Emit `item_added` after successful `@ordritem.save`.
  - [ ] Emit `item_removed` after successful destroy.

- [ ] `app/controllers/ordrs_controller.rb`
  - [ ] Emit `status_changed` when status transitions.
  - [ ] Decide canonical bill request representation: `bill_requested` vs `status_changed(to=billrequested)`.

- [ ] `app/channels/kitchen_channel.rb`
  - [ ] When staff updates status, emit `status_changed(source=staff)`.

- [ ] `app/controllers/payments/intents_controller.rb`
  - [ ] Ensure payment intent creation does not emit `paid`.

- [ ] Payment completion (webhook)
  - [ ] Add/identify webhook handler and emit `paid(source=webhook)` with idempotency.

- [ ] Voice execution path
  - [ ] Ensure any mutation triggered by voice emits events with `source=voice` and idempotency.

Consumption (Phase 2+):

- [ ] Move broadcasting triggers to “projection applied” boundary so that ActionCable payload always reflects projected truth.

## Migration plan (v1)

Phase 0 (spec + schema readiness):

- Add `order_events` table + model.
- Add sequence + idempotency constraints.

Phase 1 (emit events, no projection yet):

- Emit `OrderEvent` for add/remove item and for status changes.
- Keep `Ordraction` and current broadcasts untouched.

Phase 2 (projection on, broadcasts from projected state):

- Add projector job + per-order projection cursor.
- Gradually move broadcasting to occur after projection (materialized truth).

Phase 3 (cleanup / consolidation):

- Reduce reliance on `Ordraction` for operational truth (retain if still needed for UX/audit).
- Ensure all mutation paths are covered by event emission.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Canonical event creation

- GIVEN an existing `Ordr`
  WHEN a customer adds an item through the UI
  THEN a single `OrderEvent` is created with `event_type=item_added`, `source=guest`, and payload including `menuitem_id` and `qty`.

- GIVEN an existing `Ordr`
  WHEN staff transitions an order from `ordered` to `preparing`
  THEN a single `OrderEvent` is created with `event_type=status_changed`, `source=staff`, and payload including `from=ordered` and `to=preparing`.

- GIVEN an existing `Ordr`
  WHEN a payment intent succeeds (via webhook)
  THEN a single `OrderEvent` is created with `event_type=paid`, `source=webhook`, and payload including `provider=stripe` and the external reference.

### Deterministic reduction

- GIVEN a sequence of `OrderEvent` records for an `Ordr`
  WHEN the reducer replays events in ascending `sequence` order
  THEN the computed state is deterministic and identical for every replay.

- GIVEN an `OrderEvent` stream
  WHEN the reducer encounters an unknown `event_type`
  THEN the reducer does not corrupt state and the event is reported as unsupported.

### Projection guarantees

- GIVEN that `OrderEvent` is enabled
  WHEN any controller/service mutates an order or its items
  THEN the mutation path emits an `OrderEvent` before returning success.

- GIVEN an emitted `OrderEvent`
  WHEN projections are processed
  THEN the materialized `Ordr` / `Ordritem` state reflects the event.

## Progress Checklist

- [x] Add `order_events` table + model (`OrderEvent`)
- [x] Define event type taxonomy (v1 whitelist)
- [x] Add idempotency strategy (voice + webhooks)
- [x] Implement reducer (`OrderStateReducer`) with deterministic ordering
- [x] Implement projection worker(s) (Sidekiq): apply events to `Ordr` / `Ordritem`
- [x] Update primary mutation code paths (controllers/channels) to emit `OrderEvent`
- [x] Ensure key ActionCable broadcasts occur after projection (inline projection for interactive paths)
- [x] Add tests:
  - [x] event creation for add/remove/status transitions
  - [x] reducer determinism
  - [x] projection correctness
- [x] Add basic observability:
  - [x] log event emission failures
  - [ ] metrics for projection lag

## Ops / risk notes (v1)

- Event volume will increase (every mutation emits an `OrderEvent`). Ensure the DB index set stays healthy and monitor table growth.
- Projection lag: if projection runs async (job queue), consumers may see stale materialized state briefly. For interactive flows we can project inline (as done for key paths).
- Idempotency:
  - Voice and webhooks MUST provide stable `idempotency_key` values.
  - Use per-order uniqueness to dedupe retries safely.
- FK / deletion safety:
  - `Ordraction` has an FK to `Ordritem`. Do not hard-delete `Ordritem` rows when “removing” items.
  - Prefer `status=removed` + `ordritemprice=0` to preserve audit trails and avoid FK violations.
- Debugging:
  - Add an endpoint to inspect event stream + cursor per order (e.g. `GET /restaurants/:restaurant_id/ordrs/:id/events`).
  - This should show ordering (`sequence`) and help diagnose missing emissions or projector drift.
