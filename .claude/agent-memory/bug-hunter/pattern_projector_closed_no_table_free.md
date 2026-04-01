---
name: OrderEventProjector closed transition never frees the table
description: update_columns bypasses after_update_commit callbacks — tablesetting never reset to free and floorplan never rebroadcast when Stripe webhook closes an order
type: project
---

`OrderEventProjector.apply_status_change!` uses `ordr.update_columns(updates)` throughout. `update_columns` bypasses all `after_update_commit` callbacks. When the Stripe webhook closes an order (via `handle_checkout_session_completed` → `emit_closed_if_paid!` → `OrderEventProjector.project!`), two things silently fail:

1. `Ordr#after_update_commit :broadcast_floorplan_tile_update` never fires — the floorplan dashboard continues to show the table as occupied.
2. No code anywhere resets `Tablesetting#status` back to `:free` — the table can never be re-used until manually refreshed or a new order is started.

This is the root cause of the "Stripe payment completes but table stays occupied" regression.

**Fix**: In `apply_status_change!`, after the `closed` case, manually call `tablesetting.update_columns(status: Tablesetting.statuses['free'])` and `FloorplanBroadcastService.broadcast_tile(...)`, mirroring the existing pattern for `billrequested` → `AutoPayCaptureJob`.

**File fixed**: `app/services/order_event_projector.rb`

**Why the existing pattern uses update_columns**: The projector runs inside `ordr.with_lock` and must not trigger recursive callbacks. Using `update_columns` on the tablesetting is safe and intentional here.
