# Auto-Pay-and-Leave

## Overview
Enable customers to securely register payment details during their meal, indicate that billing information is on file, review their bill, and optionally auto-pay without staff interaction. This reduces post-meal friction and table turn time while keeping staff informed and in control.

## Goals
- [ ] Reduce wait time for customers finishing meals.
- [ ] Give staff clear visibility when a table has payment ready and when the customer has viewed their bill.
- [ ] Allow customer-initiated auto-payment when the order is ready to be charged.
- [ ] Maintain PCI compliance and strong security practices.

## Out of Scope (initial phase)
- [ ] Split-by-item granular payments across multiple customers on the same order.
- [ ] Offline-mode capture (requires network).

## User Stories
- [ ] As a customer, I can securely add a payment method during my meal so I don’t need to wait for the bill.
- [ ] As a customer, I can mark that my payment details are on file so staff know I’m ready for quick checkout.
- [ ] As a customer, I can view my itemized bill on my phone and the system records that I viewed it.
- [ ] As a customer, I can enable auto-pay so the bill is automatically charged when the restaurant marks my order as ready to bill or when I request the bill.
- [ ] As staff, I can see that a table has payment details on file and whether the customer has viewed their bill.
- [ ] As staff, I can opt out or override auto-pay when necessary (e.g., disputes, comps, cash, adjustments).

## Acceptance Criteria
- [ ] Customers can add a card via a PCI-compliant provider (e.g., Stripe) and receive clear success/failure feedback.
- [ ] Order shows indicators:
  - [ ] payment_on_file: true/false
  - [ ] viewed_bill_at: timestamp when the customer first sees the bill
  - [ ] auto_pay_enabled: true/false
- [ ] Staff UI surfaces badges for “Payment on File” and “Bill Viewed”.
- [ ] If auto_pay_enabled is true, system charges the order automatically when bill becomes chargeable (bill requested or staff marks ready-to-charge) and records success/failure.
- [ ] Staff can disable auto-pay per order before capture.
- [ ] Notifications are sent to staff on auto-pay success/failure.

## Data Model (proposed)
Extend `Ordr`:
- payment_on_file:boolean (default: false)
- payment_method_ref:string (token/id from PSP)
- payment_provider:string (e.g., "stripe")
- payment_on_file_at:datetime
- viewed_bill_at:datetime
- auto_pay_enabled:boolean (default: false)
- auto_pay_consent_at:datetime
- auto_pay_attempted_at:datetime
- auto_pay_status:string (pending/succeeded/failed)
- auto_pay_failure_reason:text (nullable)

Auditing (optional initial):
- [ ] Add `Ordraction` events for: payment_method_added, bill_viewed, auto_pay_enabled, auto_pay_disabled, auto_pay_capture_succeeded, auto_pay_capture_failed.

## Permissions
- [ ] Customer (session-linked participant) can add/remove their payment method for the active order, enable/disable auto-pay, and view bill.
- [ ] Staff can view indicators, disable auto-pay, and trigger manual capture.
- [ ] Only staff can adjust totals/discounts after auto-pay is armed, which automatically disables auto-pay until customer re-confirms.

## Customer Flows
- [ ] Add Payment Method
  - [ ] Tap “Add Payment” on SmartMenu.
  - [ ] Hosted payment element (PSP) collects card, returns a token/payment_method_id.
  - [ ] Backend stores provider + reference; sets `payment_on_file=true`, `payment_on_file_at=now`.
  - [ ] Staff view shows “Payment on File”.

- [ ] View Bill
  - [ ] Tap “View Bill” to see live totals, taxes, tip options.
  - [ ] Backend sets `viewed_bill_at=now` on first view.

- [ ] Enable Auto-Pay
  - [ ] Toggle “Auto-Pay when ready”.
  - [ ] Confirm consent dialog explains when the charge will occur.
  - [ ] Backend sets `auto_pay_enabled=true`, `auto_pay_consent_at=now`.

- [ ] Auto-Capture Triggers
  - [ ] When order transitions to “bill requested” OR staff marks “ready to charge”.
  - [ ] Pre-checks: payment_on_file=true, auto_pay_enabled=true, order.gross>0, not already captured.
  - [ ] If capture succeeds: set `auto_pay_status='succeeded'`, `auto_pay_attempted_at=now`; broadcast success; set order to paid/closed per business rules.
  - [ ] If capture fails: set `auto_pay_status='failed'`, `auto_pay_failure_reason`; notify staff; keep order open for manual resolution.

## Staff Flows
- [ ] Indicators on Staff View
  - [ ] Badge: “Payment on File” when `payment_on_file=true`.
  - [ ] Badge: “Bill Viewed” when `viewed_bill_at` present.
  - [ ] Badge: “Auto-Pay Armed” when `auto_pay_enabled=true`.
- [ ] Controls
  - [ ] “Disable Auto-Pay” toggle before capture.
  - [ ] “Charge Now” for manual capture (even if auto-pay disabled).

## UI Changes (Customer)
- [ ] Add Payment CTA on SmartMenu order header/sidebar.
- [ ] Hosted payment sheet (PSP) modal.
- [ ] Bill summary screen with tip selection and auto-pay toggle.
- [ ] Clear success/failure states and help text.

## UI Changes (Staff)
- [ ] Order header badges for Payment on File, Bill Viewed, Auto-Pay Armed.
- [ ] Auto-pay override/disable control.
- [ ] Toasts/banners for auto-pay result.

## API/Backend Endpoints (proposed)
- [ ] POST /restaurants/:id/ordrs/:ordr_id/payment_methods
  - [ ] Body: provider, payment_method_ref (token)
  - [ ] Sets payment_on_file=true
- [ ] DELETE /restaurants/:id/ordrs/:ordr_id/payment_methods
  - [ ] Removes reference, sets payment_on_file=false, disables auto-pay
- [ ] POST /restaurants/:id/ordrs/:ordr_id/auto_pay
  - [ ] Enable/disable auto-pay; record consent time on enable
- [ ] POST /restaurants/:id/ordrs/:ordr_id/view_bill
  - [ ] Idempotent; sets viewed_bill_at if not set
- [ ] POST /restaurants/:id/ordrs/:ordr_id/capture
  - [ ] Manual capture by staff

## State Machine Hooks (Ordr)
- [ ] On transitions to billrequested/ready-to-charge:
  - [ ] Enqueue AutoPayCaptureJob if `auto_pay_enabled && payment_on_file`.

## Jobs
- [ ] AutoPayCaptureJob
  - [ ] Validates chargeable state and totals
  - [ ] Calls PSP capture
  - [ ] Updates auto_pay_status, attempted_at, failure_reason
  - [ ] Broadcasts partials to customer and staff views

## Security & Compliance
- [ ] Never store raw PAN/PII; only PSP tokens/refs.
- [ ] Use client-side hosted fields/elements; do not proxy sensitive data through our servers.
- [ ] Rate-limit enable/disable and capture attempts.
- [ ] Signed URLs and CSRF protection for all endpoints.

## Edge Cases
- [ ] Zero total: auto-closes without charge; still shows as succeeded with amount=0.
- [ ] Tips: if customer selects tip on bill view, include in total; changing totals disables auto-pay until reconfirmed.
- [ ] Multiple participants: auto-pay applies to the single order; splitting is future work.
- [ ] Refunds/Voids: handled via staff tools; log events.

## Observability
- [ ] Logs for each state change and PSP interaction (non-PII).
- [ ] Metrics: time-to-pay after bill requested, auto-pay success rate, failures by code.

## Rollout Plan
- [ ] Feature flag: auto_pay.enabled per restaurant.
- [ ] Staff training note in release announcement.
- [ ] Soft launch on selected venues; monitor metrics; widen rollout.

## Open Questions
- [ ] Provider selection: Stripe first? Others later.
- [ ] How to handle partial authorizations or delayed capture (auth+capture vs immediate)?
- [ ] When to mark order as closed automatically vs awaiting kitchen sign-off.
