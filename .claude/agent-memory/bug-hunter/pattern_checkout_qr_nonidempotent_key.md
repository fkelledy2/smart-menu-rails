---
name: checkout_qr creates duplicate PaymentAttempts due to random idempotency key
description: checkout_qr Stripe path used "checkout_qr:{ordr_id}:{SecureRandom.hex(8)}" — a new random suffix on each request, so double-clicks or browser retries created multiple PaymentAttempt records
type: project
---

`OrdrPaymentsController#checkout_qr` (Stripe path) built the `PaymentAttempt` idempotency_key as `"checkout_qr:#{@ordr.id}:#{SecureRandom.hex(8)}"`. The random suffix defeats idempotency — each request creates a new `PaymentAttempt` that passes the uniqueness constraint. Double-clicks from staff (generating the QR for a customer) or network retries could create multiple open payment attempts for a single order.

**Fix applied:** Changed to `find_or_create_by!(idempotency_key: "checkout_qr:#{@ordr.id}")` — stable key per order so retries resolve to the same attempt.

**Contrast with:** `AutoPay::Orchestrator` uses `"auto_pay:#{ordr.id}"` — the right pattern for stable per-order idempotency.

**How to apply:** Any PaymentAttempt creation in a controller action (not a Sidekiq job) should use a deterministic key like `"#{action}:#{ordr_id}"`. Only add random suffixes for split payments where multiple attempts per order are intentional.
