---
name: Square inline payment missing paid OrderEvent
description: OrdrPaymentsController#create_inline_payment succeeds but never emits paid OrderEvent, never calls projector — order stuck in billrequested forever
type: project
---

`OrdrPaymentsController#create_inline_payment` creates a `PaymentAttempt` and marks it `:succeeded`, then immediately renders `{ ok: true }`. It never calls `OrderEvent.emit!(event_type: 'paid')`, never calls `OrderEventProjector.project!`, and never calls `broadcast_state`. The order stays in `billrequested` status permanently.

**Why:** The action was added for Square Web Payments SDK inline flow but was not wired into the event-sourced order lifecycle like `cash_payment` is.

**How to apply:** Any Square inline payment path that doesn't route through a webhook will silently leave orders unresolved. The fix is to emit `paid` and `closed` OrderEvents after `pa.update!(status: :succeeded)`, then call `OrderEventProjector.project!` and `broadcast_state`.
