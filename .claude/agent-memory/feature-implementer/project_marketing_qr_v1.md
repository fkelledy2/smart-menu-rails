---
name: Pre-Configured Marketing QRs v1
description: MarketingQrCode model, public resolve endpoint, admin CRUD, link/unlink service — architecture decisions and gotchas (March 2026)
type: project
---

Pre-Configured Marketing QRs feature shipped 2026-03-25.

**Why:** Decouples print production from menu deployment — allows sales to distribute physical materials before a restaurant's menu is configured. Scanning an unlinked QR shows a branded holding page rather than a broken link.

**Architecture decisions:**
- `MarketingQrCode` model with UUID token (immutable via `attr_readonly`), status enum (unlinked/linked/archived), nullable FKs to restaurant/menu/tablesetting/smartmenu.
- Public endpoint: `GET /m/:token` via `MarketingQrCodesController` (no auth required). Rate-limited at 60/min/IP via RackAttack (`marketing_qr/ip` throttle).
- Admin CRUD: `Admin::MarketingQrCodesController` gated by `require_mellow_admin!` — checks `current_user.email.end_with?('@mellow.menu')`. No Flipper flag (admin-only feature with email-domain gate).
- `MarketingQrCodes::LinkService` — idempotently finds or creates the correct `Smartmenu` record. Slug generation is global-unique (not just per-restaurant), using suffix counter on collision.
- `MarketingQrCodes::ResolveService` — returns `Result` struct with one of `:redirect_to_smartmenu`, `:holding`, or `:not_found`.
- Pundit policy (`MarketingQrCodePolicy`) — all actions gated on `user.email.end_with?('@mellow.menu')`.

**Gotchas:**
- `skip_before_action :authenticate_user!` on a public controller raises `ArgumentError` if `authenticate_user!` was never registered as a before_action. Public controllers should simply not call it (follow smartmenus_controller pattern with `except:` or just omit it). Fixed by removing the skip entirely.
- `belongs_to :created_by_user` (non-optional) makes `validates :created_by_user_id, presence: true` redundant. RuboCop `Rails/RedundantPresenceValidationOnBelongsTo` auto-corrects it out. Subsequent model tests must check `qr.errors[:created_by_user]` (association name), not `errors[:created_by_user_id]`.
- `attr_readonly :token` raises `ActiveRecord::ReadonlyAttributeError` on `update!` — tests must use `assert_raises`, not assert the value is unchanged after `update`.
- `linked_qr` fixture points to `smartmenu: one` which has `menu: ordering_menu` + `tablesetting: table_one`. Tests that assert smartmenu reuse must use those exact fixture combinations.
- `Smartmenu` slug uniqueness index is per `[restaurant_id, slug]`, not global. The service enforces global uniqueness as a precaution (using `Smartmenu.exists?(slug: candidate)`) to avoid user confusion.
- Print view rendered with `layout: false` — returns raw HTML directly (no application layout).

**How to apply:** When extending or maintaining the marketing QR system, consult `app/services/marketing_qr_codes/` for the two service objects, `app/policies/marketing_qr_code_policy.rb` for the access control pattern, and `config/initializers/rack_attack.rb` for the `marketing_qr/ip` throttle.
