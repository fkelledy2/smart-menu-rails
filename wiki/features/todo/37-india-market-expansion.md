# Feature Spec: India Market Expansion

**Status**: Backlog
**Created**: 2026-04-04
**Author**: Feature Backlog Agent
**Flipper Flags**: `india_market`, `razorpay_payments`, `upi_pay_now`, `gst_pricing`, `veg_nonveg_indicators`, `india_table_mode`, `india_claim_restaurant`

---

## Overview

This spec covers the full set of platform changes required to launch mellow.menu in the Indian market. India is a mobile-first, UPI-dominant, QR-fluent market where the competitive edge is in-venue ordering and operational efficiency — not delivery. The initiative is broken into four execution phases: Phase 0 (Razorpay + INR + GST foundations), Phase 1 (Table Mode UX, UPI flows, veg/non-veg, Hindi localisation), Phase 2 (claim-your-restaurant pipeline + menu scraping), and Phase 3 (infra scaling). Each phase is independently deployable and gated behind Flipper flags.

Target restaurants: QSR, cafés, chains, food courts, and high-volume casual dining in Bangalore, Mumbai, and Delhi NCR.

---

## Goals

- [ ] Accept UPI, card, and wallet payments via Razorpay with sub-3s checkout UX
- [ ] Display and calculate GST-inclusive pricing with compliant invoice output
- [ ] Surface veg/non-veg indicators on all menu items (legal requirement in India)
- [ ] Enable multi-user shared table ordering sessions without forced early checkout
- [ ] Support Hindi as a first-class locale alongside English
- [ ] Provide a self-serve "claim your restaurant" onboarding flow for Indian owners
- [ ] All customer-facing flows work acceptably on 3G / low-bandwidth Android

## Non-Goals (Out of Scope for v1)

- Zomato/Swiggy delivery integration — positioning is in-venue only
- HSN/SAC code assignment per menu item (deferred to v2 for GST compliance depth)
- GSTIN validation via government API (deferred; store as free-text initially)
- Spice level configuration UI beyond a simple integer scale (full modifier/add-on system is a separate spec)
- Mobile app (Android/iOS native) — Hotwire PWA behaviour is sufficient
- AWS Mumbai / Heroku Private Spaces migration (Phase 3 infrastructure concern, not in this spec)
- Additional Indian languages beyond Hindi (Tamil, Kannada, Telugu deferred to v2)
- POS integrations (deferred to Phase 2 / separate spec)
- Tip pool / staff tip distribution

---

## User Stories

**As a restaurant owner in India**, I want to connect my Razorpay account so that my customers can pay via UPI, cards, or wallets without leaving the SmartMenu.

**As a customer scanning a table QR**, I want to join a shared table session and add items at any point during the meal without being forced to pay immediately.

**As a customer at checkout**, I want to see a UPI QR code or UPI deep-link that I can complete in my preferred payments app (Google Pay, PhonePe, BHIM).

**As a customer browsing the menu**, I want to instantly identify which items are vegetarian (green dot) or non-vegetarian (red dot) as required by Indian food labelling law.

**As a restaurant owner**, I want my menu to show prices inclusive of GST and generate a GST-compliant bill with my GSTIN printed on it.

**As a new Indian restaurant owner**, I want to claim a pre-loaded restaurant profile and start accepting QR orders within minutes.

**As a kitchen operator**, I want to mark all pending items for a table as "preparing" in one tap rather than updating each individually.

**As a mellow.menu platform admin**, I want to enable India-specific features per restaurant via Flipper without affecting existing European restaurants.

---

## Technical Design

### Architecture Notes

This initiative touches six distinct subsystems. Each is designed to slot into existing patterns with no new architectural paradigms:

1. **Payments** — new `Payments::Providers::RazorpayAdapter` following the exact interface of `BaseAdapter`. The `Payments::Orchestrator` gains a `:razorpay` branch in `provider_adapter`. `PaymentProfile#primary_provider` gains a new enum value. Webhook ingest follows the existing `Payments::Webhooks::StripeIngestor` pattern.

2. **Tax / GST** — new `tax_inclusive` boolean and `tax_rate_percentage` decimal on `Restaurant`. MenuItem price remains the source of truth and is always stored as the consumer-facing (GST-inclusive) price when `tax_inclusive` is true. A `Payments::GstInvoiceBuilder` service generates the compliant bill breakdown. No changes to `Ordr`/`Ordritem` price columns.

3. **Menu item metadata** — `veg_status` enum column on `Menuitem` (`:unset`, `:vegetarian`, `:non_vegetarian`, `:vegan`, `:egg`). Rendered as colour-coded dot via a `VegStatusComponent` ViewComponent. This is additive and non-breaking for existing restaurants.

4. **Shared Table Mode** — extends `DiningSession` with a `group_token` to link multiple individual sessions at the same table. Extends `Ordr` with a `table_group_id` foreign key so items from multiple sessions collapse into one bill. No structural change to `Ordrparticipant` (the existing bill-split model remains available for final settlement).

5. **Localisation** — Hindi (`hi`) added as a supported DeepL target locale. No changes to the `Restaurantlocale` model. The existing 40-language pipeline handles ingestion; the only additions are ensuring the customer SmartMenu respects `Accept-Language: hi` and falls back gracefully.

6. **Claim Your Restaurant** — extends the existing `DiscoveredRestaurant` admin model with a `claim_token` and `claimed_at` workflow. A public `ClaimController` handles owner verification (OTP to phone/email) and converts the discovered restaurant into a live `Restaurant` tenant.

### New Dependencies

| Gem / Service | Purpose | Rationale |
|---|---|---|
| `razorpay` (official Ruby SDK) | Razorpay API calls (orders, refunds, webhooks) | Actively maintained by Razorpay; avoids raw HTTP. Version 3.x supports Orders API + webhook verification. |
| None others | — | All other requirements (GST calculation, veg indicators, Hindi i18n, shared sessions) are implemented with existing Rails/Hotwire/Stimulus stack. |

The `razorpay` gem is the only new dependency. Alternatives considered: raw `Net::HTTP` calls — rejected because Razorpay's HMAC webhook verification and retry logic are already encapsulated in the official SDK.

---

## Phase 0 — Razorpay, INR Currency, GST Pricing Foundations

**Target**: 2–3 weeks. Deployable behind `razorpay_payments` + `gst_pricing` Flipper flags. No customer-visible UI changes outside India-configured restaurants.

### Acceptance Criteria

- [ ] A restaurant with `primary_provider: :razorpay` can create a checkout session that redirects to Razorpay's hosted checkout
- [ ] Razorpay `payment.captured` webhook is verified and creates a `PaymentAttempt` with `status: :succeeded`
- [ ] Refunds route through `Payments::Orchestrator` to `RazorpayAdapter#create_full_refund!`
- [ ] `Restaurant#currency` auto-infers to `'INR'` when `country: 'IN'`
- [ ] `Restaurant#tax_inclusive` can be set to `true` with a `tax_rate_percentage` of 5 or 18
- [ ] Bill PDF/HTML output includes GSTIN, tax rate, tax amount, and base amount when `gst_pricing` flag is on
- [ ] All existing Stripe and Square payment paths unaffected

### Data Model Changes

- [ ] Migration: add `razorpay: 2` to `PaymentProfile#primary_provider` enum
- [ ] Migration: add columns to `restaurants`:
  - `tax_inclusive boolean not null default false`
  - `tax_rate_percentage decimal(5,2) default 0.0`
  - `gstin varchar(15)` (GSTIN format: 15-char alphanumeric)
  - `india_merchant_id varchar(255)` (Razorpay Account ID for MOR setup)
- [ ] Migration: add `razorpay_order_id varchar(255)` to `payment_attempts` (Razorpay's own order reference, distinct from `provider_payment_id`)
- [ ] Index: `index_payment_attempts_on_razorpay_order_id` (unique, partial where not null)
- [ ] Policy: `RestaurantPolicy` — existing; verify `update?` covers new tax fields

### Service Objects

- [ ] `app/services/payments/providers/razorpay_adapter.rb` — implements `BaseAdapter` interface:
  - `create_checkout_session!` — creates a Razorpay Order, returns `{ checkout_session_id:, checkout_url: }` (uses Razorpay hosted checkout URL)
  - `create_full_refund!` — calls Razorpay Refunds API
  - `create_payment!` — inline payment via Razorpay Payment Links or Standard Checkout JS token (for UPI deep-link flow in Phase 1)
  - `create_and_capture_intent!` — not applicable for UPI (UPI is pull-based); raises `NotImplementedError` with descriptive message
  - `refresh_credentials!` — no-op (Razorpay uses static API keys, not OAuth tokens)

- [ ] `app/services/payments/webhooks/razorpay_ingestor.rb` — mirrors `StripeIngestor` pattern:
  - Verifies HMAC-SHA256 signature using `Razorpay::Utility.verify_webhook_signature`
  - Routes `payment.captured` → `PaymentAttempt#update!(status: :succeeded)`
  - Routes `payment.failed` → `PaymentAttempt#update!(status: :failed)`
  - Routes `refund.processed` → creates `Payments::Ledger` entry
  - All other events: log and return 200

- [ ] `app/services/payments/gst_invoice_builder.rb` — pure value object:
  - Accepts `ordr:` and `restaurant:`
  - Returns structured hash: `{ base_amount:, tax_amount:, total_amount:, tax_rate:, gstin:, invoice_ref: }`
  - Used by receipt/bill view and PDF generation
  - When `tax_inclusive: false` or `gst_pricing` flag off, returns nil (caller renders standard bill)

### Controllers & Routes

- [ ] Route: `POST /webhooks/razorpay` → `payments/webhooks/razorpay#receive`
- [ ] Controller: `app/controllers/payments/webhooks/razorpay_controller.rb`
  - `skip_before_action :verify_authenticity_token`
  - Delegates entirely to `Payments::Webhooks::RazorpayIngestor`
  - Always returns 200 (Razorpay retries on non-200)
- [ ] Route: extend restaurant settings routes to expose `tax_inclusive`, `tax_rate_percentage`, `gstin` fields (PATCH on existing restaurant settings controller)

### Orchestrator Changes

```ruby
# app/services/payments/orchestrator.rb — provider_adapter method
def provider_adapter(provider)
  case provider
  when :stripe
    Payments::Providers::StripeAdapter.new
  when :razorpay
    Payments::Providers::RazorpayAdapter.new
  else
    raise ArgumentError, "Unsupported provider: #{provider}"
  end
end
```

Also extend `create_payment_attempt!` so that when `currency == 'INR'`, `amount_cents` is stored in paise (Razorpay's smallest unit; 1 INR = 100 paise — same convention as Stripe cents, no change needed to calculation logic).

### Frontend

- [ ] Restaurant settings form: add GST section (tax inclusive toggle, rate selector 5%/18%, GSTIN text field) — visible only when `gst_pricing` Flipper flag active for that restaurant
- [ ] Bill/receipt partial: conditionally render GST breakdown table row when `GstInvoiceBuilder` returns a result
- [ ] No Stimulus controller changes required for Phase 0

### Security & Authorization

- [ ] Razorpay webhook signature verified before any database write (HMAC-SHA256 on raw request body — must read `request.raw_post`, not parsed params)
- [ ] GSTIN stored as plain text — not PCI-sensitive but treat as business-sensitive; Pundit `RestaurantPolicy#update?` restricts to owner/admin
- [ ] `india_merchant_id` (Razorpay Account ID) encrypted at rest using Rails `encrypts` (ActiveRecord Encryption, already available in Rails 7.2)
- [ ] RackAttack: add rule to limit `POST /webhooks/razorpay` to 60 req/min from Razorpay IP ranges

---

## Phase 1 — Table Mode, UPI UX, Veg/Non-Veg, Hindi

**Target**: 4–6 weeks after Phase 0. Gated by `india_table_mode`, `upi_pay_now`, `veg_nonveg_indicators` Flipper flags.

### Acceptance Criteria

- [ ] Veg/non-veg dot appears on every menu item that has `veg_status` set; unset items show no dot
- [ ] Restaurant owners can bulk-set or individually set `veg_status` per menu item from the menu editor
- [ ] A table QR scan starts or joins an active shared group session; subsequent scanners at the same table see the same running order
- [ ] Any participant can add items; only the session initiator or restaurant staff can trigger checkout
- [ ] UPI QR code is displayed at pay-time using Razorpay's UPI intent URL; deep-link opens customer's default UPI app on Android
- [ ] Hindi locale (`hi`) is available as a restaurant locale option; menu item names/descriptions translate via existing DeepL pipeline
- [ ] Kitchen staff can tap "Mark all preparing" / "Mark all ready" on an `Ordr`'s item list
- [ ] Customer SmartMenu loads critical above-fold content within 3s on a simulated 3G connection (Lighthouse score >= 70 on mobile)

### Data Model Changes

- [ ] Migration: add `veg_status integer not null default 0` to `menuitems`
  - Enum: `{ unset: 0, vegetarian: 1, non_vegetarian: 2, vegan: 3, egg: 4 }`
  - Index: `index_menuitems_on_veg_status` (for bulk-filter queries)
- [ ] Migration: add `group_token varchar(64)` to `dining_sessions`
  - Index: `index_dining_sessions_on_group_token`
  - Nullable; only populated when `india_table_mode` is active for the restaurant
- [ ] Migration: add `table_group_id bigint` to `ordrs` (FK → `ordrs.id` — references the "primary" ordr for the group)
  - Index: `index_ordrs_on_table_group_id`
  - Nullable; existing single-session ordrs unaffected
- [ ] Policy: `MenuitemPolicy` — extend `update?` to allow staff to update `veg_status`

### Service Objects

- [ ] `app/services/india/table_group_session_service.rb` — manages shared table sessions:
  - `join_or_create!(smartmenu:, tablesetting:, session_token:)` — finds active `DiningSession` for tablesetting with a matching `group_token`, or creates a new one and issues a group token
  - `group_token_for(tablesetting:)` — returns the current active group token or nil
  - Expiry: inherits `DiningSession::SESSION_TTL`; all sessions in a group expire together when the primary expires

- [ ] `app/services/india/upi_payment_builder.rb` — constructs UPI intent URLs and QR payloads:
  - `intent_url(amount:, vpa:, merchant_name:, transaction_ref:)` — returns `upi://pay?...` scheme URL
  - `razorpay_qr_payload(ordr:, restaurant:)` — calls Razorpay QR Codes API to generate a dynamic QR tied to the Razorpay order
  - Used by the pay-now Turbo Frame; no direct controller logic

- [ ] `app/services/india/batch_fulfillment_service.rb` — wraps bulk `Ordritem` fulfillment updates:
  - `mark_all_preparing!(ordr:, actor:)` — updates all `pending` ordritems to `fulfillment_status: :preparing`
  - `mark_all_ready!(ordr:, actor:)` — updates all `preparing` ordritems to `fulfillment_status: :ready`
  - Broadcasts Turbo Stream update to kitchen display channel after each bulk update
  - Logs each transition to `OrdrAction` for audit trail

### Background Jobs

- [ ] `app/jobs/india/upi_payment_status_poller_job.rb` — polls Razorpay Order status for pending UPI payments (UPI is async; webhook may lag):
  - Queue: `payments` (existing)
  - Triggered: on `PaymentAttempt` creation when provider is `:razorpay` and payment method is UPI
  - Polls every 10s for up to 5 minutes; stops on `captured` or `failed` status
  - Uses exponential back-off via Sidekiq's `retry` with `sidekiq_options retry: 8`
  - On success: broadcasts `ordr_#{id}_channel` Turbo Stream to update customer payment confirmation screen

### Controllers & Routes

- [ ] Route: `POST /smartmenu/:smartmenu_id/table_groups` → `smartmenu/table_groups#create` (join or create group session)
- [ ] Route: `GET /smartmenu/:smartmenu_id/table_groups/:group_token` → `smartmenu/table_groups#show` (shared order view)
- [ ] Route: `POST /restaurants/:restaurant_id/ordrs/:ordr_id/batch_fulfillment` → `restaurants/batch_fulfillment#create`
- [ ] Controller: `app/controllers/smartmenu/table_groups_controller.rb` — thin; delegates to `India::TableGroupSessionService`
- [ ] Controller: `app/controllers/restaurants/batch_fulfillment_controller.rb` — thin; delegates to `India::BatchFulfillmentService`; Pundit-authorised to staff/owner

### Frontend

- [ ] ViewComponent: `app/components/veg_status_component.rb` — renders green/red/amber dot SVG based on `veg_status` enum value:
  - Green filled circle: vegetarian
  - Red filled circle: non-vegetarian
  - Green outline circle: vegan
  - Yellow filled circle: egg (ovo-vegetarian)
  - Used inline in `MenuitemComponent` and in the SmartMenu item card partial
- [ ] Stimulus controller: `app/javascript/controllers/upi_payment_controller.js` — handles UPI pay-now flow:
  - On mobile: fires `window.location = intent_url` to deep-link into UPI app
  - On desktop: shows Razorpay QR modal
  - Polls `/ordrs/:id/payment_status` (JSON endpoint) every 5s as client-side fallback to webhook; stops on confirmed/failed
  - Displays spinner + "Waiting for UPI confirmation..." state
- [ ] Stimulus controller: `app/javascript/controllers/table_group_controller.js` — manages shared session state:
  - On QR scan: POSTs to `table_groups#create`, stores `group_token` in `sessionStorage`
  - Subscribes to `ordr_#{group_token}_channel` for new-item Turbo Stream broadcasts
  - Shows "X people at this table" badge
- [ ] ViewComponent: `app/components/batch_fulfillment_component.rb` — kitchen action bar with "Mark all preparing" / "Mark all ready" buttons; renders as Turbo Frame; updates via Turbo Stream response

### Performance Requirements (Phase 1)

- Veg status dot: served as inline SVG via ViewComponent — zero additional HTTP requests
- SmartMenu critical path: menu JSON payload served via Cloudflare CDN with `Cache-Control: public, max-age=60`; Turbo Drive handles navigation without full page reload
- Menu item images: ensure `srcset` with WebP variants at 400px and 800px breakpoints via existing Shrine derivatives pipeline
- UPI QR code: generated server-side on first request, cached in Redis for 5 minutes per `ordr.id`

---

## Phase 2 — Claim Your Restaurant Pipeline

**Target**: 6–10 weeks. Gated by `india_claim_restaurant` Flipper flag.

### Acceptance Criteria

- [ ] Mellow.menu admin can pre-load Indian restaurants from scraping output into `DiscoveredRestaurant` with Indian-market metadata
- [ ] A public landing page `/claim/:claim_token` allows a restaurant owner to initiate a claim
- [ ] Owner verification: OTP sent to mobile number (via existing Sidekiq email job pattern, extended for SMS via a lightweight SMS adapter)
- [ ] Successful claim: `DiscoveredRestaurant` converts to a live `Restaurant` tenant, owner `User` is created and linked, `PaymentProfile` seeded with `primary_provider: :razorpay`
- [ ] Pre-loaded menu items (from scraping) are imported via the existing `OcrMenuImport` pipeline and await owner review before publishing
- [ ] Owner receives a welcome email with setup checklist (Razorpay connection, QR code download, first-table setup)

### Data Model Changes

- [ ] Migration: add columns to `discovered_restaurants`:
  - `claim_token varchar(64)` (index unique)
  - `claimed_at datetime`
  - `claimed_by_user_id bigint` (FK → `users.id`, nullable)
  - `claim_verified_at datetime`
  - `india_phone_number varchar(20)` (for OTP delivery)
  - `india_onboarding_state varchar(50) default 'unclaimed'`
  - Enum states: `unclaimed`, `claim_initiated`, `otp_sent`, `otp_verified`, `restaurant_created`
- [ ] Index: `index_discovered_restaurants_on_claim_token` (unique)
- [ ] Index: `index_discovered_restaurants_on_india_onboarding_state`
- [ ] Policy: `DiscoveredRestaurantPolicy` — extend for public claim actions (no authentication required for initiation; OTP provides verification)

### Service Objects

- [ ] `app/services/india/restaurant_claim_service.rb`:
  - `initiate!(discovered_restaurant:, phone_number:)` — generates claim token, sends OTP via `India::SmsOtpService`, transitions state to `otp_sent`
  - `verify_otp!(claim_token:, otp:)` — validates OTP, transitions to `otp_verified`
  - `convert_to_restaurant!(discovered_restaurant:)` — wraps in a transaction:
    - Creates `User` (owner role)
    - Creates `Restaurant` from `DiscoveredRestaurant` attributes
    - Seeds `PaymentProfile` with `primary_provider: :razorpay`
    - Enqueues `India::MenuImportJob` with scraped menu data
    - Transitions state to `restaurant_created`
    - Sends welcome email via `RestaurantMailer`

- [ ] `app/services/india/sms_otp_service.rb` — thin adapter for SMS delivery:
  - v1: uses a transactional SMS provider (recommended: `aws-sdk-sns` for SMS, already in AWS ecosystem; or `textlocal` gem for India-specific SMS routing)
  - Interface: `deliver!(phone_number:, otp:)` — returns `{ success: true/false, error: }`
  - OTP: 6-digit, stored as BCrypt digest on `discovered_restaurants.otp_digest`, expires in 10 minutes
  - **New dependency decision**: `aws-sdk-sns` — recommended if the team already uses AWS for other services (S3, etc.). If not, use Twilio via `twilio-ruby` gem (already widely used). Confirm before implementation.

- [ ] `app/services/india/menu_scrape_importer.rb` — adapts scraped menu JSON (from admin pipeline) into `OcrMenuImport` format for existing review workflow; no new pipeline required.

### Background Jobs

- [ ] `app/jobs/india/menu_import_job.rb` — enqueued after `convert_to_restaurant!`:
  - Queue: `default`
  - Calls `India::MenuScrapeImporter` then triggers existing `OcrMenuImport` review workflow
  - Owner is notified by ActionMailer when import is ready to review

### Controllers & Routes

- [ ] Route: `GET /claim/:claim_token` → `india/claims#show` (public, no auth)
- [ ] Route: `POST /claim/:claim_token/initiate` → `india/claims#initiate`
- [ ] Route: `POST /claim/:claim_token/verify` → `india/claims#verify`
- [ ] Route: `POST /claim/:claim_token/convert` → `india/claims#convert`
- [ ] Controller: `app/controllers/india/claims_controller.rb` — fully public (no Devise auth required until `convert`); delegates to `India::RestaurantClaimService`
- [ ] RackAttack: rate-limit OTP send to 3/hour per phone number; rate-limit verify to 5/hour per claim token

### Frontend

- [ ] ViewComponent: `app/components/india/claim_wizard_component.rb` — multi-step claim UI rendered in a single Turbo Frame:
  - Step 1: Phone number entry
  - Step 2: OTP entry
  - Step 3: Confirm restaurant details
  - Step 4: Success + next steps
- [ ] No custom Stimulus controller needed; Turbo Frame form submissions handle each step transition

---

## Phase 3 — Infrastructure Scaling (Out of Scope for This Spec)

Phase 3 covers CDN configuration tuning, potential AWS Mumbai region migration, Heroku Private Spaces evaluation, and additional payment provider integrations (PhonePe business, Paytm for Business). These are infrastructure and commercial decisions that require separate specs once Phase 0–2 are live and revenue data is available.

Tracked separately. Flag: no Flipper flag at this stage — infra changes are not feature-flagged.

---

## Security & Authorization

- [ ] Pundit policy covers all India-specific controller actions
- [ ] Tenant scoping enforced: all `Menuitem`, `Ordr`, `DiningSession` queries scoped to `restaurant_id`
- [ ] Razorpay webhook signature HMAC verified before any state mutation (raw request body, not parsed params)
- [ ] OTP stored as BCrypt digest, expires 10 minutes after generation
- [ ] `india_merchant_id` on `Restaurant` encrypted with `ActiveRecord::Encryption` (Rails 7.2 built-in)
- [ ] RackAttack rules: `/webhooks/razorpay` (60/min), OTP send (3/hour/phone), OTP verify (5/hour/token)
- [ ] Brakeman scan must pass before any India payment code merges
- [ ] UPI intent URLs must not include customer PII in query parameters — use `transaction_ref` (ordr public token) only
- [ ] `claim_token` must be generated using `SecureRandom.urlsafe_base64(48)` — 64 chars, cryptographically random
- [ ] GDPR note: India has DPDP Act 2023 (Data Protection and Digital Personal Data Protection Act). Collect only phone number for OTP; do not store raw OTP. Phone number stored only on `DiscoveredRestaurant`/`User` record, not logged.

---

## Testing Plan

### Phase 0
- [ ] Model specs: `test/models/payment_profile_test.rb` — test `:razorpay` enum value
- [ ] Model specs: `test/models/restaurant_test.rb` — test `tax_inclusive`, `tax_rate_percentage`, `gstin` validations; test `currency` auto-inference for `country: 'IN'`
- [ ] Service specs: `test/services/payments/providers/razorpay_adapter_test.rb` — stub Razorpay gem; test `create_checkout_session!`, `create_full_refund!`
- [ ] Service specs: `test/services/payments/webhooks/razorpay_ingestor_test.rb` — test signature verification (valid + tampered payload), `payment.captured`, `payment.failed` event handling
- [ ] Service specs: `test/services/payments/gst_invoice_builder_test.rb` — test 5% and 18% rate calculations; test nil return when flag off
- [ ] Controller specs: `test/controllers/payments/webhooks/razorpay_controller_test.rb` — verify 200 on valid webhook, 200 on invalid signature (must not leak error), correct `PaymentAttempt` state transitions
- [ ] Edge cases: zero-amount ordr, already-captured payment webhook replay, refund on failed payment

### Phase 1
- [ ] Model specs: `test/models/menuitem_test.rb` — test `veg_status` enum, default value `:unset`
- [ ] Model specs: `test/models/dining_session_test.rb` — test `group_token` presence/absence, TTL behaviour with group token
- [ ] Service specs: `test/services/india/table_group_session_service_test.rb` — test join existing group, create new group, expiry
- [ ] Service specs: `test/services/india/batch_fulfillment_service_test.rb` — test bulk state transitions, OrdrAction audit entries, Turbo Stream broadcast
- [ ] Service specs: `test/services/india/upi_payment_builder_test.rb` — test intent URL format, QR payload structure
- [ ] Job specs: `test/jobs/india/upi_payment_status_poller_job_test.rb` — test poll loop, stop on captured, exponential retry
- [ ] Component specs: `test/components/veg_status_component_test.rb` — test correct dot colour per enum value, no dot when `:unset`
- [ ] System test: `test/system/india_table_group_test.rb` — two browser sessions join same table, each adds items, combined bill shown

### Phase 2
- [ ] Service specs: `test/services/india/restaurant_claim_service_test.rb` — test full state machine (initiate → verify → convert), OTP expiry, duplicate claim prevention
- [ ] Service specs: `test/services/india/sms_otp_service_test.rb` — stub SMS provider; test delivery, failure handling
- [ ] Controller specs: `test/controllers/india/claims_controller_test.rb` — test RackAttack rate limits (use `Rack::Attack.enabled = true` in test)
- [ ] Edge cases: claim token replay after `restaurant_created`, OTP brute force (6th attempt blocked), discovered restaurant already claimed
- [ ] Run: `bin/fast_test` — all passing

---

## Implementation Checklist

### Phase 0 Setup
- [ ] Flipper flags created: `razorpay_payments`, `gst_pricing`
- [ ] `razorpay` gem added to Gemfile; `bundle install`
- [ ] `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` added to Heroku config vars (not committed)
- [ ] Webhook signing secret `RAZORPAY_WEBHOOK_SECRET` added to Heroku config vars
- [ ] Database migrations written and reviewed by a second engineer

### Phase 0 Core Implementation
- [ ] `PaymentProfile#primary_provider` enum extended with `:razorpay`
- [ ] `Restaurant` migration: `tax_inclusive`, `tax_rate_percentage`, `gstin`, `india_merchant_id`
- [ ] `PaymentAttempt` migration: `razorpay_order_id`
- [ ] `RazorpayAdapter` implemented and unit-tested
- [ ] `RazorpayIngestor` implemented and unit-tested
- [ ] `GstInvoiceBuilder` implemented and unit-tested
- [ ] `Payments::Orchestrator#provider_adapter` updated
- [ ] Webhook route and controller wired up
- [ ] RackAttack rule for webhook endpoint

### Phase 0 Frontend
- [ ] GST settings section added to restaurant settings form (flag-gated)
- [ ] Bill partial updated with conditional GST breakdown
- [ ] Mobile verified: GST breakdown renders cleanly on 375px viewport

### Phase 1 Setup
- [ ] Flipper flags created: `india_table_mode`, `upi_pay_now`, `veg_nonveg_indicators`
- [ ] Migrations: `menuitems.veg_status`, `dining_sessions.group_token`, `ordrs.table_group_id`

### Phase 1 Core Implementation
- [ ] `Menuitem#veg_status` enum + policy update
- [ ] `India::TableGroupSessionService` implemented and tested
- [ ] `India::BatchFulfillmentService` implemented and tested
- [ ] `India::UpiPaymentBuilder` implemented and tested
- [ ] `India::UpiPaymentStatusPollerJob` implemented and tested
- [ ] Batch fulfillment routes and controller wired up
- [ ] Table groups routes and controller wired up

### Phase 1 Frontend
- [ ] `VegStatusComponent` built and tested
- [ ] `VegStatusComponent` integrated into SmartMenu item card partial
- [ ] `VegStatusComponent` integrated into menu editor item row
- [ ] Bulk veg-status edit UI in menu editor (select all vegetarian, etc.)
- [ ] `upi_payment_controller.js` Stimulus controller built
- [ ] UPI pay-now Turbo Frame wired into checkout flow
- [ ] `table_group_controller.js` Stimulus controller built
- [ ] `BatchFulfillmentComponent` built and integrated into kitchen view
- [ ] Hindi locale (`hi`) added to DeepL supported targets list
- [ ] Lighthouse mobile score >= 70 verified on SmartMenu critical path

### Phase 2 Setup
- [ ] Flipper flag created: `india_claim_restaurant`
- [ ] SMS provider decision made and gem added (aws-sdk-sns or twilio-ruby)
- [ ] SMS provider API credentials added to Heroku config vars
- [ ] `DiscoveredRestaurant` migration: claim columns

### Phase 2 Core Implementation
- [ ] `India::RestaurantClaimService` implemented and tested (full state machine)
- [ ] `India::SmsOtpService` implemented and tested
- [ ] `India::MenuScrapeImporter` implemented
- [ ] `India::MenuImportJob` implemented and tested
- [ ] Claim routes and controller wired up
- [ ] RackAttack rules for OTP endpoints

### Phase 2 Frontend
- [ ] `India::ClaimWizardComponent` built (4-step Turbo Frame flow)
- [ ] Public claim landing page view (`/claim/:claim_token`)
- [ ] Welcome email template added to `RestaurantMailer`
- [ ] Mobile/responsive verified (claim flow must work on Android Chrome)

### Quality (All Phases)
- [ ] All tests written and passing (`bin/fast_test`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Brakeman clean (`bundle exec brakeman`)
- [ ] JS/CSS lint clean (`yarn lint`)
- [ ] Docs regenerated (`bin/generate_docs`)

### Release
- [ ] Phase 0: enable `razorpay_payments` + `gst_pricing` for 1–2 pilot restaurants only
- [ ] Phase 0: monitor `PaymentAttempt` failure rate for Razorpay vs Stripe baseline
- [ ] Phase 1: enable `india_table_mode` for pilot restaurants after 1 week of Phase 0 stability
- [ ] Phase 1: enable `veg_nonveg_indicators` globally (safe; additive, no breaking change)
- [ ] Phase 2: enable `india_claim_restaurant` after internal QA on claim flow
- [ ] All migrations safe for zero-downtime deploy: additive columns with defaults only; no column renames or drops
- [ ] Sidekiq queues monitored: `payments` queue depth during UPI polling phase

---

## Open Questions

1. **Razorpay MOR model**: Razorpay supports both "Route" (marketplace split) and direct merchant accounts. The brief says restaurant is MOR (same as Square). Confirm with Razorpay whether we use their "Route" product or standard connected accounts — this affects whether `india_merchant_id` is a Razorpay Account ID or a Route submerchant ID.

2. **SMS provider for OTP**: The spec recommends `aws-sdk-sns` (if AWS already in use) or `twilio-ruby`. Team must confirm which before Phase 2 implementation begins. India SMS requires DLT registration (Distributed Ledger Technology — mandatory for transactional SMS in India); ensure chosen provider handles DLT compliance.

3. **UPI QR vs UPI intent URL**: On mobile, `upi://` intent URL is preferred (opens UPI app directly). On desktop, Razorpay QR Code API should be used. The `UpiPaymentBuilder` handles both but confirm Razorpay's dynamic QR pricing per transaction — some tiers charge per QR generated.

4. **Table Mode bill consolidation**: When multiple `DiningSession`s share a `group_token`, should each participant's items remain on separate `Ordr` records (linked via `table_group_id`) or merged into a single `Ordr`? The spec proposes separate ordrs linked via `table_group_id` for auditability and compatibility with existing `Ordrparticipant` split logic. Confirm this is acceptable before migration.

5. **Hindi translation review**: DeepL auto-translation for Hindi is functional but may require native speaker review for food-specific terminology (menu item names, modifiers). Recommend a translation review pass before enabling the `hi` locale for production restaurants.

6. **GSTIN validation**: The spec stores GSTIN as free-text initially. GST v2 should validate format (15-char alphanumeric with checksum) and optionally verify against the government GSTIN lookup API. Flag for v2 scope.

7. **Offline resilience**: The brief mentions client-side fallback states and Sidekiq retry queues for offline resilience. The UPI poller job handles the Sidekiq retry side. Client-side: Stimulus controllers should show a "Connection lost — retrying..." banner if the polling endpoint returns a network error. This is not fully specced here — add to Phase 1 frontend detail before implementation.

---

## References

- Razorpay Orders API: https://razorpay.com/docs/api/orders/
- Razorpay Webhook Events: https://razorpay.com/docs/webhooks/
- India Food Safety and Standards Authority (FSSAI) veg/non-veg indicator mandate: FSSAI Regulation 2.2.2 (red/green dot)
- India DPDP Act 2023: https://www.meity.gov.in/data-protection-framework
- DLT Registration for India SMS: https://www.trai.gov.in/blockchain
- Existing payment adapter pattern: `app/services/payments/providers/base_adapter.rb`, `stripe_adapter.rb`
- Existing webhook ingestor pattern: `app/services/payments/webhooks/stripe_ingestor.rb`
- Existing dining session model: `app/models/dining_session.rb`
- Existing discovered restaurant model: `app/models/discovered_restaurant.rb`
- Related spec: `docs/features/todo/backlog/33-strikepay-integration.md` (webhook verification pattern)
