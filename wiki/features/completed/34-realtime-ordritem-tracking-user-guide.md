# Realtime Ordritem Tracking & Passive Customer Feedback — User Guide

Feature #34 | Completed 2026-04-01

---

## What This Feature Does

Realtime Ordritem Tracking gives customers live, per-item visibility into the kitchen and bar status of their order — without toasts, sounds, modals, or any interruption. The customer's order view updates silently as staff process items.

Staff keep their existing batch workflows intact. A single tap ("Start Kitchen", "Bar Ready") advances all matching items at once.

---

## Enabling the Feature

This feature is gated behind the `ordritem_realtime_tracking` Flipper flag.

**Enable per-restaurant (recommended for beta):**
```
# Via Flipper UI at /flipper
# Or via Rails console:
restaurant = Restaurant.find(123)
Flipper.enable(:ordritem_realtime_tracking, restaurant)
```

**Enable globally:**
```
Flipper.enable(:ordritem_realtime_tracking)
```

**Disable to roll back:**
```
Flipper.disable(:ordritem_realtime_tracking)
```

When the flag is disabled, all new UI elements are hidden and existing order lifecycle behaviour (`status` column) is completely unchanged.

---

## Setting Up Station Routing

Each menu item and menu section can be assigned a default station (`kitchen` or `bar`). When an order is placed, the `station` on each `Ordritem` is seeded from the associated `Menuitem#default_station`.

**In the menu editor:**
- Edit any menu item and set the "Default Station" to `kitchen` or `bar`
- Edit any menu section to set a section-wide default

This field controls which station the batch actions target for that item.

---

## Staff Workflow

### Kitchen Dashboard — Batch Actions

When `ordritem_realtime_tracking` is enabled, a new action bar appears at the top of the kitchen dashboard with four buttons:

| Button | Action |
|--------|--------|
| Start Kitchen | Advances all `pending` kitchen items on ALL open orders to `preparing` |
| Kitchen Ready | Advances all `preparing` kitchen items to `ready` |
| Start Bar | Advances all `pending` bar items to `preparing` |
| Bar Ready | Advances all `preparing` bar items to `ready` |

These batch actions are sent via the existing `KitchenChannel` WebSocket connection (`advance_station` action). No page reload is needed.

### Per-Item Override

Each ticket card in the kitchen dashboard has an expandable "Item fulfillment overrides" section (click the slider icon in the footer). This shows each item with its current fulfillment badge and an arrow button to advance it one step independently of the batch. This is useful when one item is ready early or needs manual correction.

### Security

Only authenticated staff (restaurant owner or active employee with `manager` or `admin` role) can trigger fulfillment transitions. Customers cannot advance items.

---

## Customer Experience

### What the Customer Sees

When `ordritem_realtime_tracking` is enabled, the customer's cart sheet (bottom sheet) shows a "Submitted" section with:

1. **Order summary badge** — a derived label at the top: `Received`, `Preparing`, `Partially Ready`, `Ready`, or `Complete`
2. **Per-item status badges** — each submitted item shows its current fulfillment status badge

These update automatically via the existing `OrdrChannel` WebSocket subscription — no page reload, no toast, no sound.

### Derived Order Summary Labels

| Condition | Label |
|-----------|-------|
| All items `pending` | Received |
| Any item `preparing` | Preparing |
| All items `ready` | Ready |
| Mixed `ready` and non-`collected` | Partially Ready |
| All items `collected` | Complete |

### On Reconnect

If the customer's WebSocket connection drops and reconnects, the order status Turbo Frame (`ordr-status-frame-{id}`) is reloaded from the server to reconcile any missed updates.

---

## Fulfillment Status Lifecycle

```
pending → preparing → ready → collected
```

Only forward transitions are permitted. Attempting to skip a step (e.g. `pending → ready`) or go backward returns an error. This is enforced by `Ordritems::TransitionStatus`.

Transitions are **idempotent**: calling the same transition twice produces exactly one `OrdritemEvent` record. The second call returns `{ noop: true }`.

---

## Audit Trail

Every fulfillment status change creates an immutable `OrdritemEvent` record with:
- `ordritem_id`, `ordr_id`, `restaurant_id` — for scoping
- `from_status`, `to_status` — integer enum values
- `occurred_at` — UTC timestamp of the transition
- `actor_type`, `actor_id` — polymorphic reference to the staff member who triggered it
- `metadata` — JSONB, includes `station`

`OrdritemEvent` records cannot be updated or deleted (enforced by `before_update` / `before_destroy` callbacks that throw `:abort`).

---

## Broadcast Payload Format

When a transition occurs, `Ordritems::BroadcastStatusChangeJob` broadcasts to `ordr_{id}_channel`:

```json
{
  "type": "order_item_status_changed",
  "ordr_id": "123",
  "ordritem_id": "456",
  "item_name": "Guinness",
  "quantity": 2,
  "station": "bar",
  "from_status": "pending",
  "to_status": "preparing",
  "customer_status_label": "Preparing",
  "occurred_at": "2026-04-01T14:32:00Z",
  "order_summary": {
    "status": "preparing",
    "label": "Preparing"
  }
}
```

This extends the existing `OrdrChannel` — no new WebSocket channel is created.

---

## Per-Item Override via HTTP

Staff can also advance a single item via HTTP (used by the JS per-item override button):

```
PATCH /ordritems/:id/advance_fulfillment
Body: { "to_status": "preparing" }
```

Requires authentication and the `transition_fulfillment_status?` Pundit permission (manager/admin employee or restaurant owner).

---

## Known Limitations (v1)

- Customer-initiated `collected` transition is out of scope — only staff can mark items collected
- No ETA or wait time prediction per item
- No push notifications (SMS, APNs, FCM)
- `ordritem_events` partition strategy deferred until table exceeds 10M rows
- `customer_status_label` localisation uses English only in v1; DeepL coverage is a Phase 4 follow-up
- The batch station actions in the kitchen dashboard advance items across all open orders restaurant-wide; per-order scoping is available via the `StationChannel`-based API (`advance_station` with `ordr_id`)

---

## Tech Debt Note

The existing `ordritems.status` enum has legacy values `preparing: 22` and `ready: 24` that semantically overlap with the new `fulfillment_status` enum. These may be rationalised in a future migration pass but are not touched in v1.
