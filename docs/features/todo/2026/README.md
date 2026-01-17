# 2026 Feature Roadmap (TODO)

This folder breaks down the 2026 roadmap into distinct, implementable features with:

- GIVEN / WHEN / THEN acceptance criteria
- Checkbox task lists for progress tracking
- Cross-references to existing feature docs in `docs/features/`

## Current System State (baseline)

- **Order lifecycle exists (state machine)**
  - `Ordr` uses AASM with statuses: `opened → ordered → preparing → ready → delivered → billrequested → paid → closed`.
  - Order mutation history exists as `Ordraction` records (actions like `additem`, `removeitem`, `requestbill`).

- **Real-time infra exists and is in production use**
  - ActionCable channels exist: `OrdrChannel` and `KitchenChannel`.
  - Kitchen dashboard (TV-oriented) is implemented.
  - See:
    - `../done/REALTIME_IMPLEMENTATION_STATUS.md`
    - `../done/KITCHEN_DASHBOARD_UI.md`

- **Voice ordering exists (customer pages), but is not “constrained-intent engine” yet**
  - Smartmenu customer voice commands are documented and partially implemented.
  - See:
    - `../in-progress/voice-menus.md`
    - `../todo/voiceApp.md`

- **Payments exist (customer pay), but not “payments moments” / stored credentials**
  - Stripe PaymentIntent creation exists (`Payments::IntentsController`).
  - SaaS billing (restaurant subscription) is separately scoped.
  - See:
    - `../todo/stripe_restaurant_payments/README.md`
    - `../todo/bill-splitting-feature-request.md`
    - `../todo/auto-pay-and-leave.md`

- **Menus are “data models”, not yet “versioned artifacts”**
  - Sorting, time restrictions, localization, OCR import exist.
  - No immutable menu versions or diffs.
  - See:
    - `../done/MENU_SORTING_IMPLEMENTATION.md`
    - `../done/MENU_TIME_RESTRICTIONS.md`

## 2026 Feature Specs Index

- `01-unified-order-state-engine-v1.md`
- `02-menu-as-versioned-artifact-v1.md`
- `03-kitchen-display-tv-v1.md`
- `04-voice-ordering-v1-constrained.md`
- `05-payments-moments-v1.md`
- `06-partner-integrations-event-driven.md`
- `07-ai-menu-insights-v1-readonly.md`
- `08-menu-experiments-ab-testing.md`
- `09-auto-pay-and-leave-v1.md`
