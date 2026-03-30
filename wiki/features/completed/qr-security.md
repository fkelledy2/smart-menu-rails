# QR Code Security — Hardening Table Links Against Abuse

## Status
- Priority Rank: #1
- Category: Launch Blocker
- Effort: M
- Dependencies: None (greenfield hardening)

## Problem Statement
mellow.menu QR codes resolve to static URLs (`/smartmenus/:slug`) where the slug never changes. Anyone who photographs, screenshots, or shares this URL can access the menu remotely and — if ordering is enabled — place fraudulent orders without being physically present at the restaurant. This is a critical pre-launch security gap that directly threatens restaurant trust and platform integrity. Phase 1 is the minimum viable security baseline; Phase 2 adds deeper fraud controls post-launch.

## Success Criteria
- Rotating public tokens replace static slugs as the QR-encoded identifier
- A `DiningSession` is created on QR scan and required for all order mutations
- Order-specific Rack::Attack throttles are in place
- Admins can regenerate a table's QR code in one click, invalidating the old one
- Old slug-based routes remain functional (redirect to new token route) with no customer disruption
- Phase 1 ships before any public restaurant goes live with ordering enabled

## User Stories
- As a restaurant owner, I want fraudulent remote orders to be blocked so my kitchen is not disrupted by fake tickets.
- As a restaurant owner, I want to regenerate a table's QR code if it is compromised, without reprinting all menus.
- As a customer, I want my dining session to be secure and private.
- As an admin, I want visibility into active sessions and the ability to terminate suspicious ones.

## Functional Requirements

### Phase 1 — Must Have (Launch Blocker)

1. `Smartmenu` model gains a `public_token` column (64-char hex, unique, indexed). Existing `slug` column is retained unchanged.
2. New public route: `GET /t/:public_token` resolves smartmenus by token; `GET /smartmenus/:slug` remains as a redirect fallback.
3. QR generation call sites (`menus_controller.rb`, `tablesettings_controller.rb`) must use the new token-based URL.
4. `Smartmenu` auto-generates a `public_token` on create via `before_create` callback. A `rotate_token!` method invalidates the old token.
5. A `DiningSession` record is created when a customer scans a valid QR token. The session token is stored in the Rails session cookie.
6. All order mutation endpoints (`POST ordritems`, `PATCH ordrs`) must run `before_action :require_valid_dining_session!`.
7. `DiningSession` expires after 90-minute hard TTL or 30-minute inactivity, whichever comes first.
8. `ExpireDiningSessionsJob` runs every 5 minutes via Sidekiq cron to deactivate expired sessions.
9. Rack::Attack throttles are added: 10 order creations per IP per 5 minutes; 20 per dining session per 10 minutes; 30 smartmenu page loads per IP per minute.
10. Admin one-click QR regeneration: `POST /restaurants/:id/tablesettings/:tablesetting_id/regenerate_qr` rotates the token and invalidates all active dining sessions for that table.
11. Invalid tokens return 404 (not 403) to avoid confirming existence.

### Phase 2 — Post-Launch Hardening

12. Table proximity code: a 2-4 character code printed on the table, validated before session creation (opt-in per restaurant via `proximity_code_enabled` boolean).
13. Geo-heuristic flagging: sessions from IP countries that don't match the restaurant's country are flagged as `suspicious`. Suspicious sessions may be blocked from ordering (opt-in).
14. Behavioural fraud scoring (`FraudScorer` service + `FraudCheckJob`) checks order-per-minute rate, cross-table device patterns, large unpaid orders, and headless browser agents.
15. Admin fraud dashboard shows active sessions, flagged sessions, and a one-click "Terminate Session" control.

## Non-Functional Requirements
- Token entropy: 64-character hex (256-bit) — not guessable, not sequential.
- No session data stored on client beyond the session cookie token.
- Statement timeouts apply (5s primary, 15s replica).
- Rate limiting must not block legitimate dining sessions.

## Technical Notes

### Services / Models
- `app/models/smartmenu.rb`: add `generate_public_token` before_create, `rotate_token!` method.
- `app/models/dining_session.rb`: new model with `SESSION_TTL = 90.minutes`, `INACTIVITY_TIMEOUT = 30.minutes`, `valid` scope, `expired?`, `touch_activity!`, `invalidate!`.
- `app/policies/dining_session_policy.rb`: new Pundit policy.

### Migrations Required
- `add_public_token_to_smartmenus` — add `public_token:string` (limit 64, unique index), backfill existing rows.
- `create_dining_sessions` — see data model below.
- `add_payment_gating_to_restaurants` — `payment_gating_enabled:boolean default:false` (Phase 1.4).
- `add_proximity_code_to_tablesettings` — Phase 2.

### Jobs
- `app/jobs/expire_dining_sessions_job.rb` — runs every 5 minutes.
- `app/jobs/expire_unpaid_orders_job.rb` — expires `pending_payment` orders older than 10 minutes (when payment gating enabled).
- `app/jobs/fraud_check_job.rb` — Phase 2, queue: `:low`.

### Services
- `app/services/fraud_scorer.rb` — Phase 2.

### Controllers
- `app/controllers/smartmenus_controller.rb`: dual lookup (token or slug fallback), session creation.
- `app/controllers/tablesettings_controller.rb`: `regenerate_qr` action.
- `app/controllers/ordritems_controller.rb`: `before_action :require_valid_dining_session!`.

### Routes
```ruby
get 't/:public_token', to: 'smartmenus#show', as: :table_link
resources :tablesettings do
  member { post :regenerate_qr }
end
```

### Rack::Attack
Extend `config/initializers/rack_attack.rb` with order/IP, order/session, and smartmenu/IP throttles.

### Flipper
- `qr_security_v1` — gate Phase 1 dining session enforcement (allows opt-in testing before hard rollout).
- `payment_gating` — per-restaurant flag for Phase 1.4.

### Data Model — DiningSession
```
dining_sessions:
  smartmenu_id:     bigint not null
  tablesetting_id:  bigint not null
  restaurant_id:    bigint not null
  session_token:    string(64) not null unique
  ip_address:       string
  user_agent_hash:  string(64)
  active:           boolean not null default: true
  expires_at:       datetime not null
  last_activity_at: datetime
  (Phase 2) ip_country: string(2)
  (Phase 2) suspicious: boolean default: false
```

## Acceptance Criteria
1. `GET /t/:valid_token` creates a `DiningSession` and stores the token in the Rails session cookie.
2. `GET /t/:invalid_token` returns 404.
3. `POST /ordritems` without a valid dining session returns 401/redirect.
4. `POST /ordritems` with an expired dining session (past 30-min inactivity) returns 401/redirect.
5. `POST /tablesettings/:id/regenerate_qr` rotates the `public_token` and deactivates all active sessions for that table.
6. Old `/smartmenus/:slug` URL redirects to the new `/t/:public_token` URL.
7. QR code generated in the restaurant dashboard encodes the new `/t/:public_token` URL.
8. Rack::Attack returns 429 when order creation exceeds 10 per IP in 5 minutes.
9. `ExpireDiningSessionsJob` marks sessions as inactive when `expires_at < now OR last_activity_at < 30.minutes.ago`.
10. `DiningSession.valid` scope excludes expired and inactive sessions.

## Out of Scope
- Phase 2 features (proximity code, geo heuristics, fraud scoring, fraud dashboard) are out of scope for launch.
- SMS verification or email verification of diners.
- Offline-mode support.

## Open Questions
1. Should payment-gating (Phase 1.4) be a launch blocker or post-launch? Recommended: post-launch for restaurants using pay-at-end model, but enforce when restaurant enables pre-payment ordering.
2. What is the UX when a dining session expires mid-meal? Recommend: redirect to QR scan prompt with a clear "Your session expired — please re-scan the QR code" message.
3. Should proximity codes (Phase 2.1) be opt-in for all restaurants at launch, or only available to specific plan tiers?
