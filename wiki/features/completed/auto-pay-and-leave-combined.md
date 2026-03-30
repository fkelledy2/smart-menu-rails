# Auto Pay & Leave (v1)

## Status
- Priority Rank: #4
- Category: Launch Enhancer
- Effort: L
- Dependencies: QR Security / DiningSession (#1), Payments::Orchestrator (Stripe PaymentIntent), Branded Receipt Email (#3)

## Problem Statement
After dining, customers must wait for a staff member to bring and process the bill — often the longest and most frustrating part of a restaurant visit. This wait damages satisfaction scores and slows table turnover. mellow.menu has the infrastructure to close this loop: customers can store a payment method, view their live bill, and enable auto-pay so the charge happens the moment they are ready. This feature reduces post-meal friction and gives restaurants a competitive edge. Staff remain in control throughout and can override at any point.

## Success Criteria
- A customer can add a Stripe-managed payment method during their meal without staff involvement.
- A customer can view their itemised bill in real time and enable auto-pay with explicit consent.
- When auto-pay triggers, the charge is attempted via Stripe and the result is broadcast to staff in real time.
- Staff UI shows "Payment on File", "Bill Viewed", and "Auto-Pay Armed" badges on active orders.
- Staff can disable auto-pay and trigger manual capture at any time.
- No raw card data passes through mellow.menu servers.
- Feature is gated behind a Flipper flag and opt-in per restaurant.

## User Stories
- As a customer, I want to add my card once during the meal so I can leave without waiting for the bill.
- As a customer, I want to see my live itemised bill and tip before enabling auto-pay.
- As a customer, I want auto-pay to trigger automatically when the restaurant marks my order ready to charge.
- As a staff member, I want to see which tables have payment ready so I can manage them efficiently.
- As a staff member, I want to disable or override auto-pay when handling comps, disputes, or cash payments.
- As a restaurant manager, I want table turnover to improve without removing staff control.

## Functional Requirements
1. Customer can tap "Add Payment Method" in the SmartMenu order view. A Stripe-hosted payment element collects the card — no PAN passes through our servers.
2. On success, backend stores `payment_method_ref` (Stripe PaymentMethod ID), `payment_provider` ('stripe'), sets `payment_on_file: true`, `payment_on_file_at: now`.
3. Customer can view an itemised bill screen showing live `Ordritem` totals, tax, and tip options. On first view, `viewed_bill_at` is set (idempotent).
4. Customer can enable auto-pay via a toggle. A consent dialog explains exactly when the charge will occur. On enable: `auto_pay_enabled: true`, `auto_pay_consent_at: now`.
5. Auto-pay triggers when the order transitions to `billrequested` OR when staff marks "ready to charge". Pre-checks: `payment_on_file && auto_pay_enabled && ordr.gross > 0 && not already captured`.
6. `AutoPayCaptureJob` is enqueued on trigger. It calls `Payments::Orchestrator` (never Stripe directly). On success: `auto_pay_status: 'succeeded'`, `auto_pay_attempted_at: now`, order transitions to `paid`, receipt sent via `ReceiptDeliveryJob`.
7. On capture failure: `auto_pay_status: 'failed'`, `auto_pay_failure_reason` populated (non-sensitive reason only), staff receives real-time notification via ActionCable, order remains open for manual resolution.
8. If totals change after auto-pay is armed (discount, comp, tip change), auto-pay is automatically disabled until customer re-confirms.
9. Staff UI shows three badges on order header: "Payment on File", "Bill Viewed", "Auto-Pay Armed".
10. Staff controls: "Disable Auto-Pay" (before capture), "Charge Now" (manual capture, even if auto-pay disabled).
11. Zero-total edge case: order auto-closes without charge; status set to `paid`, `auto_pay_status: 'succeeded'`.
12. All consent and capture events are logged as `OrdrAction` records.

## Non-Functional Requirements
- PCI compliance: no PAN or CVV stored server-side. Only PSP-managed token/reference.
- All endpoints are CSRF-protected and rate-limited (Rack::Attack).
- `AutoPayCaptureJob` is idempotent: duplicate executions must not result in double charges.
- Webhook processing for Stripe payment confirmation must be idempotent.
- Statement timeouts apply.

## Technical Notes

### Ordr Model Extensions (Migration)
```
payment_on_file:           boolean default: false
payment_method_ref:        string
payment_provider:          string
payment_on_file_at:        datetime
viewed_bill_at:            datetime
auto_pay_enabled:          boolean default: false
auto_pay_consent_at:       datetime
auto_pay_attempted_at:     datetime
auto_pay_status:           string  # pending/succeeded/failed
auto_pay_failure_reason:   text
```

### Services
- `app/services/auto_pay/capture_service.rb`: validates state, calls `Payments::Orchestrator`, updates `Ordr`, broadcasts via ActionCable.
- Do not call Stripe directly — always route through `Payments::Orchestrator`.

### Jobs
- `app/jobs/auto_pay_capture_job.rb`: Sidekiq job, unique per `ordr_id` to prevent double-fire, retry with idempotency check.

### Policies
- `app/policies/ordr_policy.rb`: extend to allow `auto_pay` and `payment_method` actions for session-linked participants.

### ActionCable
- Broadcast auto-pay result (success/failure) to the existing restaurant-scoped channel (or `FloorplanChannel` if available).

### API Endpoints (new)
```
POST   /restaurants/:id/ordrs/:ordr_id/payment_methods    # store payment method ref
DELETE /restaurants/:id/ordrs/:ordr_id/payment_methods    # remove payment method
POST   /restaurants/:id/ordrs/:ordr_id/auto_pay           # enable/disable auto-pay
POST   /restaurants/:id/ordrs/:ordr_id/view_bill          # idempotent bill view event
POST   /restaurants/:id/ordrs/:ordr_id/capture            # manual capture (staff only)
```

### State Machine Hooks
- `Ordr` state machine: on transition to `billrequested`, enqueue `AutoPayCaptureJob` if `auto_pay_enabled && payment_on_file`.

### Flipper
- `auto_pay` — per-restaurant opt-in flag. Disabled by default.

## Acceptance Criteria
1. `POST /restaurants/:id/ordrs/:ordr_id/payment_methods` with a valid Stripe token sets `payment_on_file: true` and persists `payment_method_ref` without storing card data.
2. `POST /restaurants/:id/ordrs/:ordr_id/view_bill` sets `viewed_bill_at` on first call; subsequent calls are no-ops.
3. `POST /restaurants/:id/ordrs/:ordr_id/auto_pay` with `{enabled: true}` sets `auto_pay_enabled: true` and `auto_pay_consent_at`.
4. When an order transitions to `billrequested` with `auto_pay_enabled: true` and `payment_on_file: true`, `AutoPayCaptureJob` is enqueued.
5. Successful capture sets `auto_pay_status: 'succeeded'`, transitions order to `paid`, broadcasts success to staff channel.
6. Failed capture sets `auto_pay_status: 'failed'`, preserves order in open state, broadcasts failure reason to staff channel.
7. A second execution of `AutoPayCaptureJob` for the same order that is already `paid` is a no-op (idempotent).
8. Staff can click "Disable Auto-Pay" and subsequent `billrequested` transition does not enqueue capture.
9. If `ordr.gross` changes after auto-pay is armed, `auto_pay_enabled` is reset to false.
10. Feature is invisible when `Flipper.disabled?(:auto_pay, restaurant)`.

## Out of Scope (v1)
- Forced auto-pay (customer cannot be charged without opt-in).
- Split-by-item granular payments across multiple participants (future: see bill-splitting spec).
- Offline-mode capture.
- Square payment provider support (Stripe first; Square via Orchestrator in v2).
- Tip adjustment after auto-pay capture.

## Open Questions
1. Auth+capture vs immediate capture: does the restaurant prefer to pre-authorise the card (capture later) or charge immediately on trigger? Recommend immediate capture for simplicity in v1, with auth+capture as a configuration option in v2.
2. When exactly should the order auto-close vs require kitchen sign-off? Recommend: order transitions to `paid` on successful capture; `closed` requires explicit staff action.
3. How should the "Charge Now" manual capture button behave when Stripe's PaymentIntent has not been created yet (payment method is on file but no intent exists)? Recommend: create and capture the intent in a single step via Orchestrator.
