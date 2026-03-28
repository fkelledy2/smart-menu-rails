---
name: KitchenChannel unauthenticated order status mutation
description: KitchenChannel#handle_status_update and #handle_staff_assignment lacked current_user checks — any WebSocket client could mutate order status or trigger staff-assignment broadcasts
type: project
---

`KitchenChannel#handle_status_update` had no authentication guard. The `subscribed` callback only rejects when `restaurant_id` is blank but does NOT require `current_user`. An unauthenticated customer WebSocket client (e.g. on the smartmenu guest page) could subscribe to `kitchen_123` and send `{ action: 'update_status', order_id: X, new_status: 'closed' }` to emit `status_changed` OrderEvents and close/cancel any order.

`handle_staff_assignment` had the same issue (no `current_user` guard), though it only triggers broadcasts not state changes.

**Fix applied:** Both methods now return early unless `current_user` is present. `handle_status_update` also verifies the user is the restaurant owner, an admin, or an active employee.

**How to apply:** ActionCable `receive` callbacks are NOT protected by `before_action` — every handler method must independently check `current_user` and restaurant ownership.
