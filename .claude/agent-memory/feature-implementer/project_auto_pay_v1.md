---
name: Auto Pay & Leave v1 implementation decisions
description: Architecture, key patterns, and gotchas from the Auto Pay & Leave feature (March 2026)
type: project
---

Auto Pay & Leave (Feature #4) shipped 2026-03-25. Key decisions:

**Why:** Closes the post-meal payment loop; customer stores a Stripe PaymentMethod, enables auto-pay via consent toggle, order transitions to `paid` automatically on `billrequested` trigger.

**How to apply:** Reference when building related payment or auto-close flows.

## Architecture decisions

- `Payments::Orchestrator#create_and_capture_payment_intent!` added — creates PaymentIntent + immediately confirms in one step (agreed spec: immediate capture, no auth+capture split in v1)
- `Payments::Orchestrator::CaptureError` raised on Stripe card decline or Stripe errors — rescued in `AutoPay::CaptureService`
- `Payments::SetupIntentService` creates a Stripe SetupIntent so frontend can collect card without charging — returns `client_secret` to frontend
- `AutoPay::CaptureService` owns the full capture flow: precondition guards, zero-total short-circuit, orchestrator call, Ledger write, `paid` transition via `OrderEvent`, ActionCable broadcast, receipt enqueue
- `AutoPayCaptureJob` is idempotent — checks `auto_pay_status == 'succeeded'` and skips; also skips if not capturable
- `Ordr` model: `requestbill` AASM event has `after` hook calling `enqueue_auto_pay_capture_if_armed`
- `Ordr#disarm_auto_pay_if_totals_changed!` called from `OrdrsController#calculate_order_totals` — disarms auto_pay if gross changes while armed

## Migration

`20260325120000_add_auto_pay_to_ordrs` — adds 10 columns to `ordrs`: `payment_on_file`, `payment_method_ref`, `payment_provider`, `payment_on_file_at`, `viewed_bill_at`, `auto_pay_enabled`, `auto_pay_consent_at`, `auto_pay_attempted_at`, `auto_pay_status`, `auto_pay_failure_reason`. Three partial indexes added.

## Ordraction enum extensions

Added actions 6–13: `payment_method_added`, `payment_method_removed`, `auto_pay_enabled`, `auto_pay_disabled`, `auto_pay_succeeded`, `auto_pay_failed`, `bill_viewed`, `manual_capture`.

## Routes (all nested under `restaurants/:restaurant_id/ordrs/:id/`)

- `POST payment_methods` → `auto_pay#store_payment_method`
- `DELETE payment_methods` → `auto_pay#remove_payment_method`
- `POST auto_pay` → `auto_pay#toggle_auto_pay`
- `POST view_bill` → `auto_pay#view_bill`
- `POST capture` → `auto_pay#capture`
- `POST payments/setup_intent` → `auto_pay#setup_intent`

## Flipper flag

`auto_pay` — per-restaurant opt-in. Disabled by default. Check: `Flipper.enabled?(:auto_pay, restaurant)`.

## Stimulus controllers

- `auto_pay_controller` (data-controller="auto-pay") — staff-facing badges + Disable/Charge Now buttons
- `customer_auto_pay_controller` (data-controller="customer-auto-pay") — customer-facing SmartMenu card setup + toggle

## Gotchas

- `Ordr` routes use `params[:id]` (not `params[:ordr_id]`) even when nested under ordrs resource — the controller `set_ordr` must use `params[:id]`
- `Ordraction` action enum values cannot conflict — added values 6–13; any future additions must start at 14
- `ReceiptDeliveryService` requires a valid recipient email; the CaptureService's `enqueue_receipt` is a no-op if no participant email is available (staff can send manually)
- `AutoPayCaptureJob` uses `sidekiq_options unique:` — requires sidekiq-unique-jobs gem; check if it's installed before relying on deduplication
- Zero-total path: order marked `auto_pay_status: 'succeeded'` and transitions to `paid` without calling Stripe
