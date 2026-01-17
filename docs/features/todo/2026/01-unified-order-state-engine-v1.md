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
- `event_type` (e.g. `item_added`, `item_removed`, `status_changed`, `bill_requested`, `paid`)
- `entity_type` (`order`, `item`, `participant`, `payment`)
- `entity_id` (nullable, depending on entity)
- `payload` (JSON: qty, menuitem_id, modifiers, delay_minutes, etc.)
- `source` (`guest`, `staff`, `voice`, `system`, `webhook`)
- `idempotency_key` (nullable but recommended)
- `created_at`

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
  WHEN the reducer replays events in ascending `created_at,id` order
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

- [ ] Add `order_events` table + model (`OrderEvent`)
- [ ] Define event type taxonomy (v1 whitelist)
- [ ] Add idempotency strategy (recommended for voice + webhooks)
- [ ] Implement reducer (`OrderStateReducer`) with deterministic ordering
- [ ] Implement projection worker(s) (Sidekiq): apply events to `Ordr` / `Ordritem`
- [ ] Update existing mutation code paths (controllers/services) to emit `OrderEvent`
- [ ] Ensure ActionCable broadcasts are driven by projected state changes
- [ ] Add tests:
  - [ ] event creation for add/remove/status transitions
  - [ ] reducer determinism
  - [ ] projection correctness
- [ ] Add basic observability:
  - [ ] log event emission failures
  - [ ] metrics for projection lag
