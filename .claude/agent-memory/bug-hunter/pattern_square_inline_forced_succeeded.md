---
name: Square inline payment forces :succeeded status
description: OrdrPaymentsController#create_inline_payment sets PaymentAttempt status :succeeded unconditionally, ignoring Square's actual returned status
type: project
---

`app/controllers/ordr_payments_controller.rb` line 390 unconditionally sets `status: :succeeded` on the `PaymentAttempt` after a Square inline payment.

`SquareAdapter#create_payment!` returns `status: payment['status']` in its result hash. Square can return `'APPROVED'` (pre-capture) or `'PENDING'` instead of `'COMPLETED'`. The controller ignores `result[:status]` entirely.

Result: payments Square has not settled are recorded as complete; orders advance to paid state for money that may not clear.

**Why:** Status check was omitted when wiring up the Square inline path — the Stripe path has a similar gap but the Square one is worse because Square APPROVED != settled.

**How to apply:** Payment status writes should always use the provider's returned status, not a hardcoded constant. When reviewing payment controllers, always check whether `result[:status]` is mapped to the enum before the `PaymentAttempt` update.
