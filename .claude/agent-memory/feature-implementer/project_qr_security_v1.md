---
name: QR Security v1 Implementation
description: Key decisions, patterns, and gotchas from the qr_security_v1 feature (March 2026)
type: project
---

## What was built (Phase 1 — shipped 2026-03-24)

- `public_token` column on `smartmenus` (64-char hex, unique index). Backfill migration uses Ruby SecureRandom loop — pgcrypto `gen_random_bytes()` is not available in this DB.
- `DiningSession` model with `valid` and `expired` scopes; `SESSION_TTL = 90.minutes`, `INACTIVITY_TIMEOUT = 30.minutes`.
- `GET /t/:public_token` route → `smartmenus#show_by_token` action. Returns 404 for invalid tokens.
- `DiningSessionGate` concern in `app/controllers/concerns/dining_session_gate.rb` — `require_valid_dining_session!` before_action gated behind `Flipper.enabled?(:qr_security_v1)`.
- Session gate applied to `OrdritemsController` (create/update/destroy) and `OrdrsController` (create/update), `unless: :user_signed_in?`.
- `ExpireDiningSessionsJob` runs every 5 minutes via Sidekiq cron.
- `POST /restaurants/:id/tablesettings/:tablesetting_id/regenerate_qr` — rotates token on all Smartmenus for that table and deactivates all active DiningSessions.
- Flipper flags: `qr_security_v1` (enabled globally), `payment_gating` (disabled by default).
- Rack::Attack throttles added: orders/ip, orders/session, smartmenus/ip, table_tokens/ip.
- `session_expired` page at `/session_expired` — dedicated page per user decision Q1.
- `add_payment_gating_to_restaurants` migration — `payment_gating_enabled:boolean default:false`.

**Why:** pgcrypto not available, so backfill uses Ruby loop instead of SQL. The `before_validation :generate_public_token, on: :create` pattern is required so uniqueness validation passes on `Smartmenu.new`.

**How to apply:** When adding token-based public access to any model, always use `before_validation ... on: :create` for auto-generation callbacks, not `before_create`, so the uniqueness/presence validation doesn't fail on `.valid?` calls.

## Architecture notes

- `call_show_pipeline` private method in `SmartmenusController` contains the shared rendering logic used by both `show` (slug) and `show_by_token` (token). The original `show` action is unchanged.
- DiningSession is created only when `@tablesetting.present?` — smartmenus without a table (marketing/global menus) don't get sessions.
- `rotate_token!` uses `update_all` (no callbacks) for bulk session deactivation — intentional, no validations needed for a bulk inactive flag.

## Fixtures pattern

- All smartmenu fixtures must have a 64-char `public_token` entry. Use repeating hex chars (aaaa...64, bbbb...64, etc.) for readability.
- `dining_sessions.yml` fixture added with 4 entries covering: valid, expired TTL, inactive (active:false), stale activity.
