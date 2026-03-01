# QR Code Security — Hardening Table Links Against Abuse

## 📋 Feature Overview

**Feature Name**: QR Code Security & Anti-Fraud Layer  
**Priority**: High  
**Category**: Security / Infrastructure  
**Estimated Effort**: Medium (4–6 weeks, phased)  
**Target Release**: Q2 2026  

---

## 🎯 Problem Statement

Mellow.menu's smart menu system uses QR codes that resolve to static URLs (`/smartmenus/:slug`). The `slug` is a fixed string stored on the `smartmenus` table and never changes. Anyone who photographs, screenshots, scrapes, or shares this URL can access the menu remotely and — if ordering is enabled — place fraudulent orders without being physically present at the restaurant.

### Current Architecture (Vulnerable Surface)

| Component | Current State | Risk |
|---|---|---|
| `smartmenus.slug` | Static, never rotated | Permanent URL leakage |
| `tablesettings` | No public token, referenced by internal ID | Table enumeration possible |
| Order creation | No session binding | Remote order placement |
| Rate limiting | General `Rack::Attack` throttles exist but no order-specific or table-specific throttles | Order flooding |
| Payment gating | Stripe integration exists but orders can reach kitchen before payment | Fraudulent kitchen tickets |
| QR regeneration | Not supported | No recovery from leaked QR |

### Threat Model

| # | Attack | Description | Severity |
|---|---|---|---|
| T1 | **Remote abuse** | Shared table link on WhatsApp/social → orders from outside restaurant | Critical |
| T2 | **Order flooding (DoS)** | Script hits order creation endpoint → hundreds of fake unpaid orders → kitchen chaos | Critical |
| T3 | **Table hijacking** | Attacker modifies slug/table identifier in URL to target a different table | High |
| T4 | **Competitor sabotage** | Malicious actor places fake high-value orders | High |
| T5 | **Table enumeration** | Sequential or predictable slugs allow scanning all tables | Medium |
| T6 | **Screenshot replay** | Old QR photo used days/weeks later | Medium |

---

## 🏗 Solution Architecture — Layered Defence

No single mechanism is sufficient. This spec defines **layered, independently valuable defences** that can be shipped incrementally.

---

## Phase 1 — Must Have (Weeks 1–3)

### 1.1 Signed, Rotating Public Tokens

Replace the static `smartmenus.slug` as the public-facing identifier with a cryptographically random token that can be rotated on demand.

**Current state**: `Smartmenu` has a `slug` column (string, not null, indexed). This slug is used in QR URLs and is the primary public identifier. The `slug` column and existing routes remain untouched as a fallback during migration.

#### Migration

```ruby
class AddPublicTokenToSmartmenus < ActiveRecord::Migration[7.1]
  def change
    add_column :smartmenus, :public_token, :string, limit: 64
    add_index  :smartmenus, :public_token, unique: true

    reversible do |dir|
      dir.up do
        Smartmenu.find_each do |sm|
          sm.update_column(:public_token, SecureRandom.hex(32))
        end
        change_column_null :smartmenus, :public_token, false
      end
    end
  end
end
```

#### Model Changes

```ruby
# app/models/smartmenu.rb
before_create :generate_public_token

def generate_public_token
  self.public_token = SecureRandom.hex(32)
end

def rotate_token!
  update!(public_token: SecureRandom.hex(32))
end
```

#### Route

```ruby
# config/routes.rb
get 't/:public_token', to: 'smartmenus#show', as: :table_link
```

#### Controller Lookup

```ruby
# app/controllers/smartmenus_controller.rb
def set_smartmenu
  @smartmenu = if params[:public_token]
                 Smartmenu.find_by!(public_token: params[:public_token])
               else
                 Smartmenu.find_by!(slug: params[:id])
               end
end
```

#### QR Generation

Update QR generation call sites (currently `menus_controller.rb#edit` line ~767 and `tablesettings_controller.rb#show`) to use `table_link_url(@smartmenu.public_token)`.

#### Anti-Enumeration

- 64-character hex tokens (256-bit entropy) — non-sequential, non-guessable
- Never expose `smartmenu.id` or `tablesetting.id` in public URLs
- Return **404** (not 403) for invalid tokens to prevent confirming existence

#### Mitigates: T1, T3, T5, T6

---

### 1.2 Dining Sessions with Expiry

When a QR code is scanned, create a short-lived `DiningSession` bound to the visitor's browser. All order mutations require a valid, non-expired session.

#### Migration

```ruby
class CreateDiningSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :dining_sessions do |t|
      t.references :smartmenu,     null: false, foreign_key: true
      t.references :tablesetting,  null: false, foreign_key: true
      t.references :restaurant,    null: false, foreign_key: true
      t.string     :session_token, null: false, limit: 64
      t.string     :ip_address
      t.string     :user_agent_hash, limit: 64
      t.boolean    :active,        null: false, default: true
      t.datetime   :expires_at,    null: false
      t.datetime   :last_activity_at
      t.timestamps
    end

    add_index :dining_sessions, :session_token, unique: true
    add_index :dining_sessions, [:smartmenu_id, :active]
    add_index :dining_sessions, :expires_at
  end
end
```

#### Model

```ruby
# app/models/dining_session.rb
class DiningSession < ApplicationRecord
  belongs_to :smartmenu
  belongs_to :tablesetting
  belongs_to :restaurant

  SESSION_TTL        = 90.minutes
  INACTIVITY_TIMEOUT = 30.minutes

  before_create :generate_session_token

  scope :valid, -> {
    where(active: true)
      .where('expires_at > ?', Time.current)
      .where('last_activity_at > ?', INACTIVITY_TIMEOUT.ago)
  }

  def expired?
    !active? || expires_at < Time.current || last_activity_at < INACTIVITY_TIMEOUT.ago
  end

  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  def invalidate!
    update!(active: false)
  end

  private

  def generate_session_token
    self.session_token   = SecureRandom.hex(32)
    self.expires_at      = SESSION_TTL.from_now
    self.last_activity_at = Time.current
  end
end
```

#### Flow

1. Customer scans QR → `GET /t/:public_token`
2. Controller validates token, creates `DiningSession`, stores `session[:dining_session_token]` in Rails session cookie
3. All order mutations (`POST ordritems`, `PATCH ordrs`, etc.) run a `before_action :require_valid_dining_session!`
4. Each request touches `last_activity_at`
5. Session expires after **90 min hard TTL** OR **30 min inactivity** OR on checkout
6. Expired session → redirect to QR scan prompt with flash message

#### Cleanup Job

```ruby
# app/jobs/expire_dining_sessions_job.rb
class ExpireDiningSessionsJob < ApplicationJob
  queue_as :default

  def perform
    DiningSession.where(active: true)
                 .where('expires_at < ? OR last_activity_at < ?',
                        Time.current,
                        DiningSession::INACTIVITY_TIMEOUT.ago)
                 .update_all(active: false)
  end
end
```

Schedule via `sidekiq-cron`: every 5 minutes.

#### Mitigates: T1, T2, T4, T6

---

### 1.3 Order-Specific Rate Limiting

Extend the existing `config/initializers/rack_attack.rb` with order- and table-specific throttles.

```ruby
# ── Order creation per IP: max 10 in 5 minutes ──
Rack::Attack.throttle('orders/ip', limit: 10, period: 5.minutes) do |req|
  req.ip if req.path =~ %r{/ordritems} && req.post?
end

# ── Order creation per dining session: max 20 in 10 minutes ──
Rack::Attack.throttle('orders/session', limit: 20, period: 10.minutes) do |req|
  if req.path =~ %r{/ordritems} && req.post?
    req.env['rack.session']&.dig('dining_session_token')
  end
end

# ── Smartmenu page loads per IP: max 30 per minute (anti-scraping) ──
Rack::Attack.throttle('smartmenu/ip', limit: 30, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/t/')
end
```

These complement the existing general 300 req/min/IP throttle already in place.

#### Mitigates: T2, T4

---

### 1.4 Payment-First Gating

The strongest single defence: **orders are not dispatched to the kitchen until payment is confirmed.**

#### Flow

1. Customer adds items → `ordr` created with status `pending_payment`
2. Customer taps "Confirm & Pay" → Stripe PaymentIntent created
3. Stripe webhook confirms → status transitions to `confirmed` → kitchen ticket dispatched
4. Unpaid orders auto-expire after **10 minutes** (Sidekiq job)

Fraudulent orders become **harmless unpaid records** that never reach the kitchen.

#### Configuration

Not all restaurants want pre-payment (e.g. pay-at-end models). Make this opt-in:

```ruby
# Migration
add_column :restaurants, :payment_gating_enabled, :boolean, default: false, null: false
```

When `payment_gating_enabled` is `false`, current flow is unchanged.

#### Auto-Expire Job

```ruby
# app/jobs/expire_unpaid_orders_job.rb
class ExpireUnpaidOrdersJob < ApplicationJob
  queue_as :default

  def perform
    Ordr.where(status: :pending_payment)
        .where('created_at < ?', 10.minutes.ago)
        .find_each do |ordr|
      ordr.update!(status: :expired)
      # Notify via ActionCable if needed
    end
  end
end
```

#### Mitigates: T1, T2, T4

---

### 1.5 Admin QR Regeneration (Kill Switch)

One-click button in the restaurant dashboard to rotate a table's QR token and invalidate all active sessions.

#### Controller

```ruby
# app/controllers/tablesettings_controller.rb
def regenerate_qr
  authorize @tablesetting
  smartmenu = Smartmenu.find_by!(tablesetting_id: @tablesetting.id)
  smartmenu.rotate_token!
  DiningSession.where(tablesetting: @tablesetting, active: true)
               .update_all(active: false)
  redirect_back fallback_location: edit_restaurant_path(@restaurant),
                notice: 'QR code regenerated. Old QR is now invalid.'
end
```

#### Route

```ruby
resources :tablesettings do
  member do
    post :regenerate_qr
  end
end
```

#### UI

Add to table management section in restaurant dashboard:

```
[ 🔄 Regenerate QR Code ]
```

Confirmation dialog: *"This will invalidate the current QR code. You'll need to print a new one. Continue?"*

#### Mitigates: T1, T3, T5, T6

---

## Phase 2 — Moat Mode (Weeks 4–6)

### 2.1 Table Proximity Code

When a customer scans a QR code, prompt:

> **Enter the 2-digit code printed on your table**

Prevents screenshot/remote abuse entirely.

#### Implementation

- Add `proximity_code` (string, 2–4 chars) to `tablesettings`
- Printed on a small card/sticker at the physical table
- Validated on first scan before `DiningSession` is created
- Failed attempts rate-limited (max 5 per IP per 10 minutes)
- Opt-in per restaurant via `proximity_code_enabled` boolean on `restaurants`

#### Optional Enhancement

- Auto-rotate codes daily via Sidekiq cron job
- Display current code on staff kitchen dashboard for reference

#### Mitigates: T1, T4, T6

---

### 2.2 Geo Heuristic Flagging

Use IP geolocation to flag suspicious sessions when the request origin is far from the restaurant's physical location.

#### Implementation

- Use **MaxMind GeoLite2** (free) or **Cloudflare `CF-IPCountry` header** (if fronted by Cloudflare)
- Restaurant has `country_code` (already available via address/locale)
- On session creation, compare request IP country to restaurant country
- Mismatch → flag session as `suspicious`

#### Suspicious Session Handling

- Option A: Require lightweight CAPTCHA (e.g. hCaptcha) before proceeding
- Option B: Require staff confirmation via push notification / dashboard alert
- Option C: Allow browsing menu (read-only) but block ordering

#### Data Model

```ruby
# Add to dining_sessions
t.string  :ip_country, limit: 2
t.boolean :suspicious, default: false
```

#### Mitigates: T1, T4

---

### 2.3 Behavioural Fraud Scoring (Sidekiq AI Layer)

Async heuristic checks on order patterns, leveraging the existing Sidekiq infrastructure.

#### Signals to Score

| Signal | Threshold | Action |
|---|---|---|
| Orders per minute from same session | > 5 in 2 min | Auto-suspend session |
| Same device ordering across multiple tables | > 1 table | Flag + alert staff |
| Large orders with no payment attempt | > €100, no payment in 5 min | Hold order |
| Headless browser user agent | Detected | Block session |
| Rapid page scanning (no reading time) | > 20 pages in 60s | Throttle |

#### Implementation

```ruby
# app/jobs/fraud_check_job.rb
class FraudCheckJob < ApplicationJob
  queue_as :low

  def perform(dining_session_id)
    session = DiningSession.find(dining_session_id)
    score = FraudScorer.new(session).calculate
    if score > FRAUD_THRESHOLD
      session.update!(suspicious: true, active: false)
      StaffNotificationJob.perform_later(session.restaurant_id,
        "Suspicious activity on table #{session.tablesetting.name}")
    end
  end
end
```

Enqueue after each order creation: `FraudCheckJob.perform_later(current_dining_session.id)`

#### Mitigates: T2, T4

---

### 2.4 Admin Fraud Dashboard

Add a section to the restaurant dashboard showing:

- Active dining sessions with IP, duration, order count
- Flagged/suspicious sessions with reason
- One-click "Terminate Session" action
- Historical fraud events log

This gives restaurant operators visibility and control without requiring technical knowledge.

#### Mitigates: All (observability)

---

## 📊 Implementation Priority Matrix

| Defence Layer | Effort | Impact | Dependencies |
|---|---|---|---|
| **1.1** Rotating public tokens | Small | High | Migration, route change |
| **1.2** Dining sessions | Medium | High | 1.1 (tokens), Redis |
| **1.3** Order rate limiting | Small | Medium | Existing Rack::Attack |
| **1.4** Payment-first gating | Medium | Very High | Stripe integration |
| **1.5** QR regeneration | Small | High | 1.1 (tokens) |
| **2.1** Proximity code | Small | High | None (standalone) |
| **2.2** Geo heuristics | Medium | Medium | GeoIP data source |
| **2.3** Fraud scoring | Medium | High | 1.2 (sessions), Sidekiq |
| **2.4** Fraud dashboard | Medium | Medium | 1.2, 2.3 |

---

## 🧪 Testing Strategy

### Unit Tests

- [ ] `Smartmenu#rotate_token!` generates new token, invalidates old
- [ ] `DiningSession.valid` scope excludes expired / inactive sessions
- [ ] `DiningSession#expired?` returns true for all expiry conditions
- [ ] `FraudScorer` returns correct scores for known patterns
- [ ] Rate limit rules trigger at configured thresholds

### Integration Tests

- [ ] QR scan → session created → order placement succeeds
- [ ] Expired session → order placement rejected with 401
- [ ] Token rotation → old URL returns 404
- [ ] Payment-gating flow: unpaid orders don't reach kitchen
- [ ] Proximity code: wrong code rejected, correct code creates session
- [ ] Rate limit exceeded → 429 response

### Manual / QA Tests

- [ ] Scan QR on phone → full ordering flow works
- [ ] Share URL via WhatsApp → session expires before abuse possible
- [ ] Admin regenerates QR → old QR stops working immediately
- [ ] Multiple tables simultaneously on same device
- [ ] Geo mismatch flagging (VPN test)

---

## 🔄 Migration Path

1. **Week 1**: Deploy 1.1 (tokens) + 1.5 (regeneration). QR URLs updated. Old slug routes remain as redirects.
2. **Week 2**: Deploy 1.2 (sessions) + 1.3 (rate limits). Session enforcement begins.
3. **Week 3**: Deploy 1.4 (payment gating) for opted-in restaurants.
4. **Weeks 4–6**: Phase 2 features rolled out incrementally.

### Backward Compatibility

- Old `/smartmenus/:slug` route remains functional (redirects to `/t/:public_token`)
- Existing printed QR codes continue to work until explicitly regenerated
- No breaking changes to the `ordrs` or `ordrparticipants` tables
- Payment gating is opt-in per restaurant

---

## 💡 Strategic Notes

- **Chargeback protection**: Payment-first gating also reduces chargeback liability surface
- **Enterprise readiness**: Session-based security + fraud scoring is expected by enterprise restaurant groups
- **Stripe approval**: Better fraud controls improve Stripe risk assessment for MOR (Merchant of Record) model
- **Low support burden**: Self-service QR regeneration + auto-expiring sessions = fewer support tickets
- **Valuation multiple**: Demonstrable security infrastructure increases platform valuation for investors

---

## 📁 Files Affected (Estimated)

### New Files
- `app/models/dining_session.rb`
- `app/jobs/expire_dining_sessions_job.rb`
- `app/jobs/expire_unpaid_orders_job.rb`
- `app/jobs/fraud_check_job.rb` (Phase 2)
- `app/services/fraud_scorer.rb` (Phase 2)
- `db/migrate/xxx_add_public_token_to_smartmenus.rb`
- `db/migrate/xxx_create_dining_sessions.rb`
- `db/migrate/xxx_add_payment_gating_to_restaurants.rb`
- `db/migrate/xxx_add_proximity_code_to_tablesettings.rb` (Phase 2)

### Modified Files
- `app/models/smartmenu.rb` — `generate_public_token`, `rotate_token!`
- `app/models/tablesetting.rb` — proximity code association (Phase 2)
- `app/controllers/smartmenus_controller.rb` — token-based lookup, session creation
- `app/controllers/tablesettings_controller.rb` — `regenerate_qr` action
- `app/controllers/ordritems_controller.rb` — `require_valid_dining_session!`
- `config/routes.rb` — `/t/:public_token` route, `regenerate_qr` member route
- `config/initializers/rack_attack.rb` — order + table throttles
- `app/views/menus/edit_2025.html.erb` — QR URL generation updated
- `app/views/restaurants/sections/tables_2025.html.erb` — regenerate button
