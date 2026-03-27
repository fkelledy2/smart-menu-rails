---
name: JWT Token Management v1
description: Admin-issued JWT tokens for restaurant API integrations — architecture, key decisions, and gotchas (March 2026)
type: project
---

## Feature: JWT Token Management (API) — #8

Shipped 2026-03-27. Spec at `docs/features/completed/mellow-admin-jwt-token-management-feature-request.md`.

### Architecture decisions

- **HS256 not RS256**: Existing `JwtService` uses HS256 with `JWT_SECRET_KEY` env var. Admin-issued tokens follow the same algorithm for consistency. RS256 can be adopted later if enterprise customers require auditable key rotation.
- **Token hash stored, not raw JWT**: SHA-256 of the raw JWT is stored in `admin_jwt_tokens.token_hash`. Raw JWT is shown once in a one-request flash and never persisted.
- **Dual auth in BaseController**: `authenticate_api_user!` tries admin JWT first (via `Jwt::TokenValidator`) when `jwt_api_access` Flipper flag is on, then falls back to the existing session JWT (`JwtService.user_from_token`). Existing API controllers required zero changes to support this.
- **Scope enforcement via `enforce_scope!` helper**: Called per-action in menus/orders controllers. Returns 403 when scope missing. The `enforce_scope!` method short-circuits only for JWT requests (`api_jwt_request?`).
- **Rate limiting via RackAttack**: Per-token throttles keyed on `jwt_token:ID:minute` and `jwt_token:ID:hour`. These are DB lookups at throttle-evaluation time; acceptable given Rack::Attack's cache layer.

### Key files created

- `app/models/admin_jwt_token.rb` — validations, scopes, status helpers, `revoke!`, `record_usage!`
- `app/models/jwt_token_usage_log.rb` — immutable log; `record_timestamps=false`, `purgeable` scope
- `app/services/jwt/token_generator.rb` — generates signed JWT, stores hash, returns `Result` struct
- `app/services/jwt/token_validator.rb` — validates incoming JWT signature + DB lookup; returns typed error symbols
- `app/services/jwt/scope_enforcer.rb` — single-method permission check
- `app/controllers/concerns/jwt_authenticated.rb` — concern used by analytics/dashboard; has its own `authenticate_jwt_token!` and `log_api_usage`
- `app/controllers/admin/jwt_tokens_controller.rb` — full CRUD minus destroy; `send_email`, `download_link`, `revoke`
- `app/controllers/api/v1/analytics/dashboard_controller.rb` — JWT-only analytics endpoint; `enforce_scope!('analytics:read')`
- `app/policies/admin_jwt_token_policy.rb` — `mellow_admin?` guard (admin + @mellow.menu email)
- `app/mailers/jwt_token_mailer.rb` — `token_delivery` sends raw JWT to recipient
- `app/mailers/admin_mailer.rb` — `jwt_token_expiry_warning` for 7-day expiry notices
- `app/jobs/jwt_token_expiry_notification_job.rb` — daily job: notify expiring, purge 90-day-old logs

### Modified files

- `app/controllers/api/v1/base_controller.rb` — dual-auth in `authenticate_api_user!`, added `api_jwt_request?`, `enforce_scope!`, `log_api_usage_for_current_request`
- `app/controllers/api/v1/menus_controller.rb` — `enforce_menu_scope!` before_action
- `app/controllers/api/v1/orders_controller.rb` — `enforce_orders_scope!` before_action
- `app/controllers/api/v1/restaurants_controller.rb` — `enforce_settings_read_scope!` before_action
- `config/routes.rb` — admin jwt_tokens resource, analytics/dashboard nested route
- `config/initializers/rack_attack.rb` — per-token rate limit throttles
- `config/initializers/flipper.rb` — `jwt_api_access` flag registered (disabled by default)

### Gotchas

- **JSONB fixture arrays**: YAML fixture string values like `'["menu:read"]'` are inserted as JSONB strings (type=string), not arrays. The DB check constraint `jsonb_typeof(scopes) = 'array'` rejects them. Solution: use ERB `<%= ['menu:read'].to_json %>` in the fixture — Rails serializes the Ruby array to a JSON string which PG parses as a JSON array.
- **HTTP Verb Confusion (Brakeman)**: `request.get?` returns false for HEAD requests. Fixed by using `request.get? || request.head?` in scope enforcement guards.
- **Flash for one-time JWT display**: `flash[:raw_jwt]` survives exactly one redirect. The integration test must `follow_redirect!` before asserting the flash content is rendered — the flash hash itself is consumed after the redirect cycle.
- **JwtAuthenticated concern vs BaseController dual-auth**: The analytics/dashboard controller uses the full `JwtAuthenticated` concern (skips `authenticate_api_user!`). The menus/orders/restaurants controllers use the BaseController dual-auth path and add `enforce_scope!` calls per-action. These are two different integration points; don't confuse them.

### Flipper flag

`jwt_api_access` — disabled by default. Enable globally or per-restaurant via the Flipper UI once admin has issued and tested at least one token.

**Why:** The flag protects existing API consumers from the new admin-JWT validation path until it has been verified in production.
