---
name: Branded Receipt Email v1 — implementation decisions and architecture
description: Receipt email delivery system: models, services, jobs, policy, routes, Stimulus controller, Flipper flags, and test patterns (March 2026)
type: project
---

## Completed: 2026-03-25

### New files created
- `app/models/receipt_delivery.rb` — tracks delivery attempts per Ordr; statuses: pending/sent/failed; auto-generates `secure_token` on create; `update_column` used for `increment_retry!` to avoid Rails/SkipsModelValidations RuboCop violation
- `app/services/receipt_delivery_service.rb` — validates order state (paid/closed only) and email format before creating ReceiptDelivery and enqueuing job; raises `DeliveryError` for validation failures
- `app/services/receipt_template_renderer.rb` — renders receipt data from Ordr; `as_plain_text` for SMS/text fallback; currency symbol map for EUR/GBP/USD/AUD/CAD
- `app/mailers/receipt_mailer.rb` — `customer_receipt(receipt_delivery:)` keyword arg; uses branded `mailer` layout
- `app/jobs/receipt_delivery_job.rb` — Sidekiq job with `sidekiq_options retry: 3`; calls `deliver_now` directly (not `deliver_later`) to control retry_count tracking
- `app/controllers/receipt_deliveries_controller.rb` — `create` (staff, auth required, Pundit) and `self_service` (public, rate-limited); uses `skip_before_action` for the 3 application_controller before_actions on self_service
- `app/policies/receipt_delivery_policy.rb` — owner/employee can create/index/show; `self_service?` permits anyone (rate limiting is Rack-level)
- `app/javascript/controllers/receipt_request_controller.js` — Stimulus controller for customer receipt form; uses `fetch` with CSRF token, inline error/success feedback via `status` target

### Modified files
- `app/models/ordr.rb` — added `has_many :receipt_deliveries`
- `app/models/restaurant.rb` — added `has_many :receipt_deliveries`
- `config/routes.rb` — added `post :send_receipt` nested under restaurant/ordr, and `post '/receipts/request'` as public self-service route
- `config/initializers/rack_attack.rb` — added `receipts/email` (5/10min per email) and `receipts/ip` (10/10min per IP) throttles
- `config/initializers/flipper.rb` — registered `:receipt_email` (disabled by default) and `:receipt_sms` (disabled by default, stretch goal)
- `app/assets/config/manifest.js` — added `//= link controllers/receipt_request_controller.js` (missing this caused 187 test errors!)

### Views created
- `app/views/receipt_mailer/customer_receipt.html.erb` — full itemised receipt, tax/tip rows conditional, branded layout
- `app/views/receipt_mailer/customer_receipt.text.erb` — delegates to `@renderer.as_plain_text`
- `app/views/ordrs/_send_receipt_modal.html.erb` — staff Bootstrap modal with Flipper gate; renders only for paid/closed orders
- `app/views/smartmenus/_receipt_request_form.html.erb` — customer self-service form with GDPR consent checkbox
- `app/views/receipt_deliveries/_send_receipt_success.html.erb` — Turbo Stream success replacement
- `app/views/receipt_deliveries/_send_receipt_error.html.erb` — Turbo Stream error replacement

### Migration
- `20260325094758_create_receipt_deliveries.rb` — creates `receipt_deliveries` table with FK to `ordrs` and `restaurants`

### Flipper flags
- `:receipt_email` — disabled by default; enable per-restaurant via Flipper UI before rollout
- `:receipt_sms` — disabled by default; Twilio not implemented in v1

### Key gotchas
1. **Asset manifest must list every Stimulus controller** — forgetting `receipt_request_controller.js` caused 187 system/integration test errors with "Asset not declared to be precompiled"
2. **IdentityCache caches restaurant association on ordr** — tests that update `restaurant.currency` and then use `@ordr.restaurant.currency` get stale data; call `@ordr.reload` after restaurant column updates in tests
3. **Service uses keyword args** — test `build_service` helper must use `**overrides` (double-splat), not positional hash merge, when building the service
4. **`assert_enqueued_with` and `assert_emails`** — require `include ActiveJob::TestHelper` and `include ActionMailer::TestHelper` respectively; neither is in the default `ActiveSupport::TestCase`
5. **SMS delivery is a stub** — `deliver_sms` raises `NotImplementedError`; guarded by `:receipt_sms` Flipper flag so the job marks it failed cleanly without raising in production
6. **`increment!` cop** — `Rails/SkipsModelValidations` warns on `increment!`; use `update_column(:retry_count, retry_count + 1)` instead

### Payment data: no card last-4 stored
The `Ordr` model has `gross`, `tax`, `tip`, `nett` float columns. `PaymentAttempt` has `amount_cents` and `provider` but no card last-4. Receipt email omits payment method detail per spec requirement to never expose sensitive payment data.

### Restaurant image
`restaurant.image` is a Shrine attachment (`ImageUploader::Attachment(:image)`). Use `restaurant.image_url` in views. Guard with `if @restaurant.respond_to?(:image) && @restaurant.image` before calling `.image_url`.
