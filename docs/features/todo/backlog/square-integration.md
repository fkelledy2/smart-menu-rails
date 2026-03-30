# Square Integration

## Status
- Priority Rank: IN-PROGRESS (not ranked — under active development; alpha testing is the immediate next step)
- Category: Launch Enhancer (unlocks Square-market restaurant acquisition on GA)
- Effort: XL (substantially complete — see epic checklist below for remaining items)
- Dependencies: Payments::Orchestrator (built), ProviderAccount model (extended), Flipper (`square_payments` flag registered)
- Refined: true

**Implementation state (2026-03-30):** Epics 1–8 backend/UI complete. Three items remain before alpha: (a) split-bill progress UI, (b) manager notification email on degraded/disconnected status, (c) "Reconnect Square" CTA in admin UI. Alpha testing (Square sandbox, deployed environment) is the current blocker for pilot cohort configuration and GA.

**Original spec fields (preserved below for reference):**

**Status:** In Progress (Epics 1–6 complete, Epic 7 mostly complete, Epic 8 UI done — pending alpha testing)
**Priority:** High
**Target:** 2026
**Feature flag:** `square_payments` (Flipper, registered in `config/initializers/flipper.rb`)

---

## 1. Goals

- Allow a restaurant to choose **Square** instead of **Stripe** as its single payment provider.
- Restaurant remains **Merchant of Record (MoR)**.
- Support taking payment inside `/smartmenu`:
  - **Inline card entry** (Square Web Payments SDK), or
  - **Square-hosted checkout** (Payment Link / Checkout API) — configurable per restaurant.
- Support **tips**, **split bills**, **Apple Pay**, and **Google Pay**.
- Payment status is **webhook-driven**; `Ordr` is the master record.
- Platform fee support using Square's **application fee** feature.
- **Sandbox** support in all non-production environments (Square sandbox endpoints/tokens are environment-scoped).

## 2. Non-Goals

- **Refunds** — not supported in V1.
- **Chargebacks / disputes** — not surfaced in mellow.
- **Receipts** — Square issues receipts on behalf of the MoR.
- **Multi-location per menu** — V1 stores one `square_location_id` per restaurant.

---

## 3. Square Concepts → mellow.menu Mapping

| Square Concept | mellow.menu Concept | Notes |
|---|---|---|
| Seller Account | `Restaurant` | One seller per restaurant |
| Location | `restaurant.square_location_id` | Picked during OAuth connect |
| Payment | `PaymentAttempt` | Extended with `provider: :square` |
| Payment Link / Checkout | Hosted checkout mode | `restaurant.square_checkout_mode = :hosted` |
| Application Fee | `payment_attempts.platform_fee_cents` | Already exists in schema |
| OAuth Token | `ProviderAccount` (encrypted) | Extended for Square |
| Webhook | `Payments::Webhooks::SquareIngestor` | Mirrors `StripeIngestor` |

### Square Locations (V1 Decision)

On connect, fetch seller locations and store a default `square_location_id` on the `Restaurant`. If the seller has multiple locations, the restaurant manager picks one in the connect UI. Supporting "different location per menu" is out of scope for V1.

---

## 4. Existing Payment Architecture (Reference)

The codebase already has a provider abstraction layer. Square extends it.

### Current Service Layer

```
app/services/payments/
├── orchestrator.rb              # Entry point — delegates to provider adapter
├── funds_flow_router.rb         # Determines charge pattern (direct/destination)
├── normalized_event.rb          # Provider-agnostic webhook event wrapper
├── ledger.rb                    # Append-only ledger of all payment events
├── providers/
│   ├── base_adapter.rb          # Interface: create_checkout_session!, create_full_refund!
│   ├── stripe_adapter.rb        # Stripe implementation
│   └── stripe_connect.rb        # Stripe OAuth onboarding
├── webhooks/
│   └── stripe_ingestor.rb       # Stripe webhook → NormalizedEvent → Ledger + side-effects
└── refunds/
    └── creator.rb               # Refund orchestration
```

### Current Models

| Model | Provider enum values | Notes |
|---|---|---|
| `PaymentProfile` | `stripe: 0` | Per-restaurant, `primary_provider` + `merchant_model` |
| `ProviderAccount` | `stripe: 0` | Per-restaurant, stores `provider_account_id`, `status`, `capabilities` |
| `PaymentAttempt` | `stripe: 0` | Per-order payment record with `provider_payment_id` |
| `PaymentRefund` | `stripe: 0` | Linked to `PaymentAttempt` |
| `LedgerEvent` | `stripe: 0` | Append-only audit log |
| `OrdrSplitPayment` | — | Has `stripe_checkout_session_id`, `stripe_payment_intent_id` columns |

### Current Order States

| Status | Value | Description |
|---|---|---|
| `opened` | 0 | Initial — items can be added |
| `ordered` | 20 | Submitted to kitchen |
| `preparing` | 22 | Kitchen working |
| `ready` | 24 | Ready for serving |
| `delivered` | 25 | Delivered to table |
| `billrequested` | 30 | Customer requested bill |
| `paid` | 35 | Payment confirmed |
| `closed` | 40 | Finalised |

---

## 5. Domain Model Changes

### 5.1 Schema Migrations

#### `restaurants` — new columns

```ruby
add_column :restaurants, :payment_provider, :string, default: 'stripe'
add_column :restaurants, :payment_provider_status, :integer, default: 0
  # enum: disconnected(0), connected(10), degraded(20)
add_column :restaurants, :square_checkout_mode, :integer, default: 0
  # enum: inline(0), hosted(10)
add_column :restaurants, :square_location_id, :string
add_column :restaurants, :square_merchant_id, :string
add_column :restaurants, :square_application_id, :string
add_column :restaurants, :square_oauth_revoked_at, :datetime
add_column :restaurants, :platform_fee_type, :integer, default: 0
  # enum: none(0), percent(10), fixed(20), percent_plus_fixed(30)
add_column :restaurants, :platform_fee_percent, :decimal, precision: 5, scale: 2
add_column :restaurants, :platform_fee_fixed_cents, :integer
```

#### `provider_accounts` — token storage + environment ✅ DONE

> **Completed:** Migration `20260304224700_add_square_fields_to_provider_accounts`
> added encrypted token columns, environment, scopes, and lifecycle timestamps.
> `ProviderAccount` model updated with `encrypts :access_token, :refresh_token`,
> `square: 1` enum, environment validation, and token expiry helpers.
> Rails ActiveRecord Encryption configured via `config/initializers/active_record_encryption.rb`
> using env vars (`ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, etc.).

```ruby
add_column :provider_accounts, :access_token_ciphertext, :text
add_column :provider_accounts, :refresh_token_ciphertext, :text
add_column :provider_accounts, :token_expires_at, :datetime
add_column :provider_accounts, :environment, :string, default: 'production', null: false
add_column :provider_accounts, :scopes, :text
add_column :provider_accounts, :connected_at, :datetime
add_column :provider_accounts, :disconnected_at, :datetime
change_column_null :provider_accounts, :provider_account_id, true
```

#### `payment_attempts` — idempotency + tips

```ruby
# Extend provider enum in model: square: 1

add_column :payment_attempts, :idempotency_key, :string
add_column :payment_attempts, :tip_cents, :integer, default: 0
add_column :payment_attempts, :provider_checkout_url, :string
add_index  :payment_attempts, :idempotency_key, unique: true,
           where: "idempotency_key IS NOT NULL"
```

#### `ordr_split_payments` — now provider-agnostic ✅ DONE

> **Completed:** Migration `20260304220000_make_ordr_split_payments_provider_agnostic`
> renamed Stripe-specific columns and added provider discriminator. All referencing
> code (model, controller, ingestor, spec) updated. No backward-compat shim needed
> since Stripe payments have not yet gone to production.

```ruby
# Destructive rename (no production data exists)
rename_column :ordr_split_payments, :stripe_checkout_session_id, :provider_checkout_session_id
rename_column :ordr_split_payments, :stripe_payment_intent_id, :provider_payment_id

# New columns
add_column :ordr_split_payments, :provider, :integer, default: 0, null: false
  # stripe(0), square(1)
add_column :ordr_split_payments, :idempotency_key, :string
add_column :ordr_split_payments, :tip_cents, :integer, default: 0, null: false
add_column :ordr_split_payments, :payer_ref, :string

add_index :ordr_split_payments, :idempotency_key, unique: true,
          where: "idempotency_key IS NOT NULL"
add_index :ordr_split_payments, [:provider, :provider_payment_id], unique: true,
          where: "provider_payment_id IS NOT NULL"
```

#### All other payment models — extend provider enum

In `LedgerEvent`, `PaymentProfile` (`:primary_provider`), `PaymentRefund`: add `square: 1`.

### 5.2 Model Additions

#### `Restaurant`

```ruby
enum :payment_provider_status,
     { disconnected: 0, connected: 10, degraded: 20 }, prefix: :provider
enum :square_checkout_mode,
     { inline: 0, hosted: 10 }, prefix: :square
enum :platform_fee_type,
     { none: 0, percent: 10, fixed: 20, percent_plus_fixed: 30 }, prefix: :fee

def square_provider?  = payment_provider == 'square'
def stripe_provider?  = payment_provider == 'stripe'
def square_connected? = square_provider? && provider_connected?

def compute_platform_fee_cents(amount_cents)
  case platform_fee_type
  when 'none'              then 0
  when 'percent'           then (amount_cents * (platform_fee_percent.to_d / 100)).ceil
  when 'fixed'             then platform_fee_fixed_cents.to_i
  when 'percent_plus_fixed'
    (amount_cents * (platform_fee_percent.to_d / 100)).ceil + platform_fee_fixed_cents.to_i
  else 0
  end
end
```

---

## 6. Service Architecture

### 6.1 BaseAdapter Extension

```ruby
module Payments::Providers
  class BaseAdapter
    # Existing
    def create_checkout_session!(...) = raise NotImplementedError
    def create_full_refund!(...)      = raise NotImplementedError

    # New — inline payment (Square Web Payments SDK)
    def create_payment!(payment_attempt:, ordr:, source_id:,
                        amount_cents:, currency:, tip_cents: 0,
                        verification_token: nil)
      raise NotImplementedError
    end

    # New — credential lifecycle
    def refresh_credentials!(provider_account:)
      raise NotImplementedError
    end
  end
end
```

### 6.2 SquareAdapter

```
app/services/payments/providers/square_adapter.rb
```

Key methods:

- **`create_payment!`** — Inline flow. Sends `source_id` (card nonce from Web Payments SDK) to Square `POST /v2/payments` with `idempotency_key`, `amount_money`, `tip_money`, `app_fee_money`, `location_id`, and `reference_id` (= order id).
- **`create_checkout_session!`** — Hosted flow. Calls `POST /v2/online-checkout/payment-links` with line items, redirect URL, accepted payment methods, and tipping config.
- **`refresh_credentials!`** — Token refresh via `POST /oauth2/token` with `grant_type=refresh_token`.

Internal dependencies:
- `SquareHttpClient` — thin Faraday wrapper with `Authorization: Bearer`, `Square-Version` header, JSON parsing, and typed error handling (`SquareApiError`).

### 6.3 SquareConnect (OAuth)

```
app/services/payments/providers/square_connect.rb
```

Mirrors `Payments::Providers::StripeConnect`:

- **`authorize_url`** — Builds Square OAuth URL with `client_id`, scopes, `state`, `redirect_uri`.
- **`exchange_code!`** — Exchanges auth code for tokens; stores encrypted in `ProviderAccount`; fetches merchant profile + locations.
- **`revoke!`** — `POST /oauth2/revoke`; marks restaurant disconnected.
- **`refresh_token!`** — `POST /oauth2/token` with `grant_type=refresh_token`.

**Requested OAuth scopes:**

| Scope | Purpose |
|---|---|
| `PAYMENTS_WRITE` | Create payments |
| `PAYMENTS_READ` | Read payment status |
| `MERCHANT_PROFILE_READ` | Read seller name |
| `ORDERS_WRITE` | Create orders for hosted checkout |
| `ORDERS_READ` | Read order details |
| `ONLINE_STORE_SITE_READ` | Payment link access |

### 6.4 SquareIngestor (Webhooks)

```
app/services/payments/webhooks/square_ingestor.rb
```

Mirrors `StripeIngestor` structure:

| Square Event | Normalized Type | Side-Effect |
|---|---|---|
| `payment.completed` | `:succeeded` | Mark `PaymentAttempt` succeeded → emit `paid` `OrderEvent` → project + broadcast |
| `payment.updated` | `:updated` | Update `PaymentAttempt` status |
| `payment.failed` | `:failed` | Mark `PaymentAttempt` failed |
| `oauth.authorization.revoked` | `:revoked` | Mark restaurant disconnected, block payments, notify manager |

All events are normalized via `Payments::NormalizedEvent` and appended to `Payments::Ledger` for the audit trail.

### 6.5 Orchestrator Extension

> **Note:** The `Orchestrator#provider_adapter` currently only handles `:stripe`. Square inline payments bypass the Orchestrator entirely (via `OrdrPaymentsController#create_inline_payment` → `SquareAdapter#create_payment!`). The hosted checkout path uses `OrdrPaymentsController#checkout_session` which calls `SquareAdapter#create_checkout_session!` directly. Adding `:square` to the Orchestrator's `provider_adapter` is a clean-up item but not blocking.

```ruby
# Payments::Orchestrator#provider_adapter (current — Stripe only)
def provider_adapter(provider)
  case provider
  when :stripe  then Payments::Providers::StripeAdapter.new
  else raise ArgumentError, "Unsupported provider: #{provider}"
  end
end

# Target state:
# when :square  then Payments::Providers::SquareAdapter.new(restaurant: ordr.restaurant)
```

### 6.6 FundsFlowRouter Extension

Square always uses `:direct` charge pattern when restaurant is MoR. Platform fees are collected via `app_fee_money` on the payment itself (Square's application fee feature).

---

## 7. API Endpoints

### 7.1 OAuth Connect (Admin — authenticated)

| Method | Path | Action |
|---|---|---|
| `GET` | `/restaurants/:id/payments/square/connect` | Redirect to Square OAuth |
| `GET` | `/restaurants/:id/payments/square/callback` | Exchange code, store tokens |
| `DELETE` | `/restaurants/:id/payments/square/disconnect` | Revoke tokens, mark disconnected |
| `GET` | `/restaurants/:id/payments/square/locations` | Fetch locations for picker |
| `PATCH` | `/restaurants/:id/payments/square/location` | Save chosen location |

**Controller:** `Payments::SquareConnectController` (mirrors `Payments::StripeConnectController`)

### 7.2 SmartMenu Payment (Customer — session-based)

| Method | Path | Action |
|---|---|---|
| `POST` | `/smartmenu/orders/:id/payments` | Inline payment (card nonce) |
| `POST` | `/smartmenu/orders/:id/payment_link` | Create hosted checkout link |
| `GET` | `/smartmenu/orders/:id/payment_return` | Return from hosted checkout |
| `GET` | `/smartmenu/orders/:id/payments/:pid/status` | Poll payment status |

#### Inline Payment Flow

```
POST /smartmenu/orders/:id/payments
{
  "source_id": "cnon:card-nonce-ok",
  "verification_token": "verf:...",
  "tip_cents": 200,
  "split_payment_id": null
}
```

1. Create `PaymentAttempt` with `idempotency_key` (UUID)
2. Call `SquareAdapter#create_payment!` with source token + amounts
3. Return `{ status: "succeeded"|"pending"|"failed" }`

#### Hosted Checkout Flow

```
POST /smartmenu/orders/:id/payment_link
{ "tip_cents": 200, "split_payment_id": null }
```

1. Create `PaymentAttempt` with `idempotency_key`
2. Call `SquareAdapter#create_checkout_session!` with line items + redirect URL
3. Return `{ checkout_url: "https://square.link/..." }` → client redirects

#### Payment Return

```
GET /smartmenu/orders/:id/payment_return?op=<payment_attempt_id>
```

Renders "Processing payment…" screen. Does **not** mark as paid — waits for webhook. Client polls `/payments/:pid/status` until confirmed.

### 7.3 Webhook Endpoint

| Method | Path | Action |
|---|---|---|
| `POST` | `/webhooks/square` | Receive Square webhook events |

**Signature verification:** Validate `x-square-hmacsha256-signature` header using webhook signature key + notification URL + raw request body (per Square docs).

**Processing:** Enqueue `Square::WebhookProcessorJob.perform_async(event_id, raw_body)` → job calls `SquareIngestor#ingest!`.

---

## 8. Frontend — Stimulus Controllers

### 8.1 Inline Checkout: `square_payment_controller.js`

```
app/javascript/controllers/square_payment_controller.js
```

Stimulus controller that:

1. Loads Square Web Payments SDK (`https://sandbox.web.squarecdn.com/v1/square.js` or `https://web.squarecdn.com/v1/square.js`)
2. Initializes with `applicationId` + `locationId` (from `data-` attributes)
3. Attaches **Card** payment method to a container element
4. Attaches **Apple Pay** + **Google Pay** buttons (when eligible, checked via `payments.applePay()` / `payments.googlePay()`)
5. On submit:
   - `card.tokenize()` → returns one-time `source_id`
   - (Optional) Buyer verification flow for SCA → returns `verification_token`
   - `POST /smartmenu/orders/:id/payments` with `source_id` + `verification_token` + `tip_cents`
6. Show success / error state

**Targets:**
- `cardContainer` — div for card fields
- `applePayContainer` — div for Apple Pay button
- `googlePayContainer` — div for Google Pay button
- `submitButton` — pay button
- `tipInput` — tip amount selector
- `errorMessage` — error display
- `processingOverlay` — "Processing…" spinner

**Values:**
- `applicationId` — Square app ID
- `locationId` — restaurant's Square location
- `orderId` — current order ID
- `currency` — e.g. "EUR"
- `amountCents` — total due

### 8.2 Tip Selector (shared)

Tip selection UI (preset percentages + custom amount) is provider-agnostic and shared between Stripe and Square flows. Emits a `tip:changed` custom event with `{ tipCents }`.

### 8.3 Split Bill UI (shared)

Split bill selection (pay full / split equally by N / custom amounts) is also provider-agnostic. Creates `OrdrSplitPayment` records server-side and renders a per-payer payment form.

---

## 9. Admin UI — Settings → Payments

### 9.1 Provider Selector

```erb
<%# app/views/restaurants/sections/_payments_settings.html.erb %>
```

- **Radio:** Stripe or Square (enforced single provider)
- Warning if switching with open orders

### 9.2 Square Configuration (shown when provider = square)

| Setting | Control | Notes |
|---|---|---|
| Connect status | Badge + "Connect Square" / "Disconnect" button | OAuth flow |
| Square seller name | Read-only text | From merchant profile |
| Location | Dropdown (if multiple) | Fetched on connect |
| Checkout mode | Radio: Inline / Hosted | `square_checkout_mode` |
| Apple Pay | Toggle | Default: on |
| Google Pay | Toggle | Default: on |
| Platform fee % | Number input | `platform_fee_percent` |
| Platform fee fixed | Number input (cents) | `platform_fee_fixed_cents` |

### 9.3 Disconnect Flow

1. Click "Disconnect Square"
2. Warning modal: "Disconnecting will prevent new payments. Recommend doing this outside of service hours. Any open/unpaid orders will need to be settled manually."
3. On confirm:
   - Revoke OAuth tokens
   - Set `payment_provider_status = :disconnected`
   - Set `square_oauth_revoked_at`
   - Block new payments immediately

---

## 10. Split Bills

### 10.1 Data Model

Split bill = multiple `OrdrSplitPayment` records against the same `Ordr`.

Order is "Paid" when `sum(completed.total_cents) >= order.total_due_cents`.

### 10.2 Customer UX (V1)

At "bill requested" or "pay now":
1. Choose: **Pay full bill** / **Split equally** (enter N) / **Custom split** (amounts per payer)
2. Each payer completes their own payment (inline or hosted)
3. Progress display: "€X of €Y paid"

### 10.3 Guardrails

- Enforce `amount_cents > 0` per split
- **Exact match only** — no overpay in V1
- Idempotency per payer action (unique `idempotency_key` per `OrdrSplitPayment`)
- Provider-agnostic: `OrdrSplitPayment.provider` tracks which provider processed each split

---

## 11. Order State & Payment Timing

### 11.1 V1 Rule: Payment at Submit

Payment is taken **immediately at order submit**.

On successful payment completion:
- Transition `opened → ordered`
- Gate the `opened → ordered` transition on payment success when payment is required

### 11.2 `billrequested` State

Kept for future pay-later flows. No change to existing state machine.

### 11.3 Webhook Reconciliation

- Webhook updates `PaymentAttempt` / `OrdrSplitPayment` status
- Order state transitions happen **only** through `OrderEvent` domain logic (service object)
- `OrderEventProjector` enforces invariants

---

## 12. Idempotency & Reliability

### 12.1 Idempotency

- Generate UUID `idempotency_key` per payment attempt
- Persist on `payment_attempts.idempotency_key` and `ordr_split_payments.idempotency_key`
- Pass through to Square `CreatePayment` / `CreatePaymentLink` (Square supports idempotency keys natively)

### 12.2 Failure Modes

| Scenario | Handling |
|---|---|
| Payment succeeds but order submit fails | Order is created first, then payment attempted. If webhook arrives before order commit, Sidekiq retries reconcile. |
| Order submit succeeds but payment fails | Keep order in `opened` with "payment failed" banner; allow retry. |
| Webhook delayed | Show "Processing…" screen; client polls `/payments/:pid/status` (polls DB, not Square). |
| Token expired | Background refresh job; "Reconnect Square" CTA if refresh fails. |

### 12.3 Ledger Deduplication

`LedgerEvent` enforces uniqueness on `provider_event_id`. Duplicate webhook deliveries are safely no-oped (same pattern as `StripeIngestor`).

---

## 13. Background Jobs (Sidekiq)

| Job | Schedule | Purpose |
|---|---|---|
| `Square::RefreshTokenJob` | Daily | Refresh access tokens within N days of expiry |
| `Square::HealthCheckJob` | Weekly (optional) | `GET /v2/locations` to verify token validity |
| `Square::WebhookProcessorJob` | On-demand (enqueued) | Process a single webhook event |

### Token Refresh Failure

1. Mark `payment_provider_status = :degraded`
2. Notify manager (email + in-app notification)
3. "Reconnect Square" CTA in admin UI

---

## 14. Configuration (Heroku)

### 14.1 Environment Variables

```bash
# Environment selection (mapped from Rails.env)
SQUARE_ENV=production|sandbox    # non-prod → sandbox

# Production credentials
SQUARE_PROD_APP_ID=sq0idp-...
SQUARE_PROD_CLIENT_ID=sq0idp-...
SQUARE_PROD_CLIENT_SECRET=sq0csp-...
SQUARE_WEBHOOK_SIGNATURE_KEY_PROD=...

# Sandbox credentials
SQUARE_SANDBOX_APP_ID=sandbox-sq0idp-...
SQUARE_SANDBOX_CLIENT_ID=sandbox-sq0idp-...
SQUARE_SANDBOX_CLIENT_SECRET=sandbox-sq0csp-...
SQUARE_WEBHOOK_SIGNATURE_KEY_SANDBOX=...

# API version pin
SQUARE_API_VERSION=2024-12-18
```

### 14.2 Secrets

- OAuth access/refresh tokens: encrypted via Rails 7 ActiveRecord Encryption in `provider_accounts` table.
- **Never** expose Square access token to the browser.
- Web Payments SDK `applicationId` is public (safe to embed in HTML `data-` attributes).

### 14.3 Square API Base URLs

| Environment | OAuth | API |
|---|---|---|
| Production | `https://connect.squareup.com/oauth2` | `https://connect.squareup.com/v2` |
| Sandbox | `https://connect.squareupsandbox.com/oauth2` | `https://connect.squareupsandbox.com/v2` |

---

## 15. SCA / Buyer Verification

Square Web Payments SDK supports a **buyer verification** flow for Strong Customer Authentication (SCA). V1 approach:

- Implement the token plumbing now: `card.tokenize()` → `verifyBuyer()` → pass `verification_token` to backend.
- Store `verification_token` in payment request.
- **Enforce for EU** once exact SCA requirement per restaurant country/region is confirmed.
- Default: percent-only platform fee (e.g., 1.5%), configurable per restaurant.

---

## 16. Testing Plan

### 16.1 Unit Tests

- `SquareAdapter` — `create_payment!`, `create_checkout_session!` (mock HTTP)
- `SquareConnect` — `authorize_url`, `exchange_code!`, `revoke!`, `refresh_token!`
- `SquareIngestor` — event normalization, ledger append, side-effects
- `BaseAdapter` interface compliance for `SquareAdapter`
- Signature verification (known fixtures; ensure raw body used)
- Idempotency (double POST creates single Square payment)
- `Restaurant#compute_platform_fee_cents` edge cases

### 16.2 Integration Tests (Sandbox)

- OAuth connect + location selection (single and multi-location sellers)
- Inline card payment success / failure
- Hosted checkout link creation → redirect → return
- Apple Pay / Google Pay (where feasible in test env)
- Webhook processing: `payment.completed` → `PaymentAttempt` + `Ordr` status updated
- Webhook processing: `oauth.authorization.revoked` → restaurant disconnected
- Split bill: two payers each pay half → order marked paid on second completion
- Token refresh flow

### 16.3 Resilience Tests

- Webhook retry behavior (duplicate `provider_event_id` → no-op)
- Delayed webhook simulation (client polls status)
- Expired token + refresh failure → degraded status

---

## 17. Rollout Plan

### 17.1 Feature Flags

| Flag | Scope | Purpose |
|---|---|---|
| `payments.square.enabled` | Global (Flipper) | Gate all Square code paths |
| `restaurant.payment_provider` | Per-restaurant column | `stripe` or `square` |

### 17.2 Phases

1. **Alpha** — Internal testing with Square sandbox
2. **Pilot** — Select restaurants (feature flag per restaurant)
3. **GA** — General availability; provider selector in Settings → Payments

---

## 18. File Manifest (New Files)

### Services

| File | Purpose |
|---|---|
| `app/services/payments/providers/square_adapter.rb` | Square payment adapter |
| `app/services/payments/providers/square_connect.rb` | Square OAuth flow |
| `app/services/payments/providers/square_http_client.rb` | Faraday wrapper for Square API |
| `app/services/payments/webhooks/square_ingestor.rb` | Square webhook processing |

### Controllers

| File | Purpose |
|---|---|
| `app/controllers/payments/square_connect_controller.rb` | OAuth connect/callback/disconnect/locations |
| `app/controllers/payments/square_webhooks_controller.rb` | Webhook endpoint + signature verification |

### Jobs

| File | Purpose |
|---|---|
| `app/jobs/square/refresh_token_job.rb` | Daily token refresh (tokens expiring within 7 days) |
| `app/jobs/square/health_check_job.rb` | Weekly connectivity check (`GET /v2/locations`) + degraded/disconnected handling |

### Frontend

| File | Purpose |
|---|---|
| `app/javascript/controllers/square_payment_controller.js` | Stimulus controller for Web Payments SDK |

### Views

| File | Purpose |
|---|---|
| `app/views/restaurants/sections/_settings_2025.html.erb` | Admin payment config UI (Square Connect card section) |
| `app/views/smartmenus/_square_inline_payment.html.erb` | Reusable Square inline card + wallet partial (Stimulus controller wiring) |

### Migrations

| File | Purpose |
|---|---|
| `db/migrate/20260304230000_add_square_fields_to_restaurants.rb` | Restaurant columns (provider, status, checkout mode, location, merchant, fees) |
| `db/migrate/20260304224700_add_square_fields_to_provider_accounts.rb` | Encrypted token storage, environment, scopes, lifecycle timestamps |
| `db/migrate/20260304230100_add_idempotency_to_payment_attempts.rb` | Idempotency key, tip_cents, provider_checkout_url |
| `db/migrate/20260304220000_make_ordr_split_payments_provider_agnostic.rb` | Rename Stripe-specific columns, add provider enum + idempotency |
| `db/migrate/20260305080000_rename_provider_account_token_columns.rb` | Rename ciphertext columns to plain names (AR Encryption handles encryption) |

### Tests

| File | Purpose |
|---|---|
| `test/services/payments/providers/square_adapter_test.rb` | SquareAdapter unit tests |
| `test/services/payments/providers/square_connect_test.rb` | SquareConnect unit tests |
| `test/services/payments/providers/square_http_client_test.rb` | SquareHttpClient unit tests |
| `test/services/payments/webhooks/square_ingestor_test.rb` | SquareIngestor unit tests |
| `test/controllers/payments/square_connect_controller_test.rb` | OAuth flow integration tests |
| `test/controllers/payments/square_webhooks_controller_test.rb` | Webhook endpoint integration tests |
| `test/models/restaurant_square_integration_test.rb` | Restaurant model Square integration tests |

---

## 19. Open Items & Defaults

| Item | Default | Notes |
|---|---|---|
| Platform fee | Percent-only, 1.5%, configurable per restaurant | Override via admin UI |
| SCA enforcement | Plumbing implemented; enforced per restaurant country TBD | Buyer verification token passed when available |
| Split bill exactness | Exact total paid == amount due (no overpay) | Simplest V1 approach |
| Square SDK version | Pinned via `SQUARE_API_VERSION` env var | Upgrade intentionally |
| Wallet support regions | Apple Pay + Google Pay enabled by default | Browser/device eligibility checked at runtime |

---

## 20. Implementation Epics

### Epic 1: Foundation (Schema + Provider Abstraction) ✅ DONE

- [x] Migrations: `20260304230000_add_square_fields_to_restaurants`, `20260304224700_add_square_fields_to_provider_accounts`, `20260304230100_add_idempotency_to_payment_attempts`, `20260304220000_make_ordr_split_payments_provider_agnostic`, `20260305080000_rename_provider_account_token_columns`
- [x] Extend all provider enums with `square: 1` — `PaymentAttempt`, `LedgerEvent`, `PaymentProfile`, `PaymentRefund`, `ProviderAccount`, `OrdrSplitPayment`
- [x] `Restaurant` model: enums (`payment_provider_status`, `square_checkout_mode`, `platform_fee_type`) + `compute_platform_fee_cents` + `square_provider?` + `square_connected?`
- [x] `ProviderAccount` model: `encrypts :access_token, :refresh_token`, `square: 1` enum, environment validation, token expiry helpers
- [x] `SquareHttpClient` — Faraday wrapper with auth, versioned headers, JSON parsing, typed `SquareApiError`
- [x] Unit tests: `restaurant_square_integration_test.rb`, `square_http_client_test.rb`

### Epic 2: OAuth Connect ✅ DONE

- [x] `SquareConnect` service — `authorize_url`, `exchange_code!`, `revoke!`, `refresh_token!`, `fetch_locations`
- [x] `SquareConnectController` — connect, callback, disconnect, locations, update_location (5 actions with Pundit authorization)
- [x] Routes: `GET square/connect`, `GET square/callback`, `DELETE square/disconnect`, `GET square/locations`, `PATCH square/location`
- [x] Admin UI: Square Connect card in `_settings_2025.html.erb` — connect/disconnect buttons, merchant & location display, checkout mode selector (inline vs hosted)
- [x] Integration tests: `square_connect_controller_test.rb`, `square_connect_test.rb`

### Epic 3: Inline Payments (Web Payments SDK) ✅ DONE

- [x] `SquareAdapter#create_payment!` — sends `source_id` to Square `POST /v2/payments` with idempotency, amounts, app fee, location
- [x] `square_payment_controller.js` Stimulus controller — loads SDK, initializes Card + Apple Pay + Google Pay, tokenize → POST, buyer verification (SCA)
- [x] Card tokenization + buyer verification — `card.tokenize()` → `verifyBuyer()` → `verification_token` passed to backend
- [x] Apple Pay + Google Pay attachment — checked via `payments.applePay()` / `payments.googlePay()`, hidden when unavailable
- [x] `POST /restaurants/:id/ordrs/:id/payments/inline` endpoint → `OrdrPaymentsController#create_inline_payment`
- [x] Tip selector integration — Stimulus controller reads `#tipNumberField` fallback from shared tip UI
- [x] Unit + integration tests: `square_adapter_test.rb`, `ordr_payments_controller_test.rb`

### Epic 4: Hosted Checkout ✅ DONE

- [x] `SquareAdapter#create_checkout_session!` — calls `POST /v2/online-checkout/payment-links` with line items, redirect URL, tipping config
- [x] Provider-aware checkout endpoint: `POST /restaurants/:id/ordrs/:id/payments/checkout_session` routes to Square or Stripe based on `restaurant.square_provider?`
- [x] Payment return handled by existing redirect flow — client redirects to `success_url` after hosted checkout
- [x] Tip configuration included in Square hosted checkout options
- [x] Tests: covered in `ordr_payments_controller_test.rb` (checkout routing tests)

### Epic 5: Webhooks ✅ DONE

- [x] `SquareIngestor` service — normalizes events, updates `PaymentAttempt`/`OrdrSplitPayment`, emits `OrderEvent`, broadcasts state
- [x] `POST /webhooks/square` endpoint + HMAC-SHA256 signature verification (`SquareWebhooksController`)
- [x] Async processing via `Payments::WebhookIngestJob.perform_later` with inline fallback on enqueue failure
- [x] `payment.completed` → mark `PaymentAttempt` succeeded → emit `paid` + `closed` `OrderEvent` → project + broadcast
- [x] `payment.updated` → update status; `payment.failed` → mark failed
- [x] `oauth.authorization.revoked` → disconnect restaurant, block payments, log warning
- [x] Ledger integration — `LedgerEvent` created for every normalized event with `provider_event_id` uniqueness
- [x] Tests: `square_webhooks_controller_test.rb`, `square_ingestor_test.rb`

### Epic 6: Split Bills (Square) ✅ DONE (core flow — progress UI pending)

- [x] Provider-agnostic split payment creation — `OrdrSplitPayment` has `provider` enum (`stripe: 0`, `square: 1`), `idempotency_key`, `tip_cents`, `payer_ref`
- [x] Per-payer inline / hosted payment flow — `checkout_session` and `create_inline_payment` both accept `ordr_split_payment_id`
- [ ] Progress tracking ("€X of €Y paid") — customer-facing progress UI not yet built
- [x] Fully-paid detection → order status transition — `SquareIngestor#emit_paid_if_settled!` checks if `sum(succeeded) >= order total`
- [x] Integration tests: split_evenly + Square split settlement tests in `ordr_payments_controller_test.rb`

### Epic 7: Background Jobs + Credential Lifecycle ✅ MOSTLY DONE

- [x] `Square::RefreshTokenJob` (daily) — refreshes tokens expiring within 7 days, logs per-account results
- [x] `Square::HealthCheckJob` (weekly) — calls `GET /v2/locations`, marks degraded on failure, auto-restores on success, disconnects on 401
- [x] Degraded status handling — `HealthCheckJob` sets `payment_provider_status: :degraded` or `:disconnected`; admin UI shows account status (humanized)
- [ ] Manager notification email on degraded/disconnected status
- [ ] Explicit "Reconnect Square" CTA in admin UI when status is degraded/disconnected

### Epic 8: Rollout ✅ DONE (backend + admin UI + customer-facing UI)

- [x] Flipper flag `square_payments` — registered in `config/initializers/flipper.rb`, disabled by default
- [x] Admin UI: Square Connect card in `_settings_2025.html.erb` — connect/disconnect buttons, merchant & location display, checkout mode selector (inline vs hosted)
- [x] Stimulus: `square_payment_controller.js` — loads Square Web Payments SDK, Card + Apple Pay + Google Pay, tokenize → POST, buyer verification (SCA), tip fallback from `#tipNumberField`
- [x] Payment endpoint: `POST /restaurants/:id/ordrs/:id/payments/inline` → `OrdrPaymentsController#create_inline_payment`
- [x] Customer-facing UI wiring:
  - [x] `smartmenu.html.erb` layout — provider meta tags (`payment-provider`, `square-application-id`, `square-location-id`, `square-sandbox`), conditional Stripe/Square SDK loading, `data-payment-provider` on body
  - [x] `_square_inline_payment.html.erb` — reusable partial rendering Stimulus controller with all targets and data values
  - [x] `_cart_bottom_sheet.html.erb` — provider-aware: Square inline renders card form + `data-action` on Pay button; Stripe keeps wallet controller; Square hosted skips wallet
  - [x] `_showModals.erb` — provider-aware staff pay modal with same conditional rendering
  - [x] `ordr_commons.js` — `pay-order-confirm` handler detects `data-payment-provider`; Square inline ensures bill requested then lets Stimulus handle tokenize+submit; Stripe/hosted keeps redirect flow
  - [x] `state_controller.js` — dynamic pay section builder renders Square card container with all Stimulus data attributes or Stripe wallet based on provider
- [x] Integration tests: 13 tests, 46 assertions in `ordr_payments_controller_test.rb`
- [x] Full test suite green (3,455 runs, 9,701 assertions, 0 failures)
- [ ] Alpha testing (sandbox) — requires deployed environment
- [ ] Pilot cohort configuration — via Flipper UI per-restaurant
- [ ] GA release — enable `square_payments` flag globally
