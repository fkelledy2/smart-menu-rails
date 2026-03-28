---
name: Auto-pay capture never enqueued via event-first order flow
description: AutoPayCaptureJob is only enqueued from the AASM requestbill event callback, but the event-first flow (OrderEventProjector) uses update_columns which bypasses AASM — auto-pay silently never fires
type: project
---

`Ordr` defines an AASM `requestbill` event with an `after` callback that calls `enqueue_auto_pay_capture_if_armed`. But the production order flow uses `OrderEventProjector.apply_status_change!` which calls `ordr.update_columns(status: ...)`. `update_columns` bypasses ActiveRecord callbacks, validations, and AASM entirely.

Additionally, the `requestbill!` AASM event method is never called anywhere in the application (confirmed by grep). Auto-pay capture is completely dead in the event-first architecture.

**Why:** The AASM state machine was the original order lifecycle mechanism but the codebase migrated to an event-sourced flow. The AASM callbacks were not ported to the projector.

**How to apply:** The fix is to add auto-pay enqueueing directly in `OrderEventProjector.apply_status_change!` when `to_key == 'billrequested'`, after `ordr.update_columns`. Pattern: `AutoPayCaptureJob.perform_later(ordr.id) if ordr.auto_pay_capturable?`
