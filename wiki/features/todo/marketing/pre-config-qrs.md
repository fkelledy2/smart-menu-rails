# Pre-Configured Marketing QR Codes

## Status
- Priority Rank: #6
- Category: Launch Enhancer
- Effort: M
- Dependencies: QR Security (#1) — specifically the public token infrastructure and `/t/:public_token` route pattern

## Problem Statement
mellow.menu's sales and onboarding process requires restaurant operators to have physical marketing materials (table tents, window stickers, flyers) before their menu goes live. Under the current architecture, QR codes cannot be generated until a menu and table setup exist — meaning sales cannot place printed materials ahead of launch. This creates a bottleneck where restaurants cannot go live quickly because physical materials lag digital configuration. Pre-configured marketing QR codes decouple print production from menu deployment.

## Success Criteria
- A mellow.menu admin (`@mellow.menu` email) can generate a branded, printable marketing QR code before a menu or table exists.
- Before linking, scanning the QR shows a "Coming Soon" holding page.
- After linking to a restaurant/menu/table, scanning the QR redirects to the correct SmartMenu flow.
- The physical QR code never changes — only the link destination changes.
- Only `@mellow.menu` users can create, link, or manage marketing QR codes.

## User Stories
- As a mellow.menu admin, I want to generate and print marketing QR codes before a restaurant's menu is configured so physical materials can be distributed early.
- As a mellow.menu admin, I want to link a marketing QR code to a specific menu or table after the restaurant is set up.
- As a restaurant owner, I want physical materials distributed before launch to scan correctly once we go live — without reprinting.
- As a customer scanning an unlinked QR, I want to see a professional "Coming Soon" page rather than a broken link.

## Functional Requirements
1. New model `MarketingQrCode` with fields: `token` (UUID, immutable), `status` (enum: `unlinked`, `linked`, `archived`), `holding_url` (string, optional), `restaurant_id` (nullable FK), `menu_id` (nullable FK), `tablesetting_id` (nullable FK), `smartmenu_id` (nullable FK, cached resolution), `name`, `campaign`, `created_by_user_id`.
2. Public endpoint: `GET /m/:token` — if `unlinked`, render holding page or redirect to `holding_url`; if `linked`, resolve to the correct `Smartmenu` slug and redirect to `/t/:public_token` (using QR Security's token infrastructure).
3. Admin UI (under existing admin namespace): list, create, link, unlink, print/download QR codes.
4. Routes: `GET /admin/marketing_qr_codes`, `POST /admin/marketing_qr_codes`, `PATCH /admin/marketing_qr_codes/:id/link`, `PATCH /admin/marketing_qr_codes/:id/unlink`, `GET /admin/marketing_qr_codes/:id/print`.
5. Access restricted to users where `current_user.email.ends_with?('@mellow.menu')`. Enforce via `before_action :require_mellow_admin!` and a Pundit policy.
6. QR generation reuses the existing `QRCodeStyling` JS and branded print layout. Encoded URL: `https://mellow.menu/m/:token`.
7. Linking: admin selects a restaurant, then optionally a menu and/or tablesetting. On link, if no matching `Smartmenu` exists, find-or-create it idempotently using the existing SmartMenu generation pattern.
8. Unlinking: sets `status: 'unlinked'` — the QR reverts to the holding experience.
9. Existing `/smartmenus/:slug` and `/t/:public_token` QR codes are unaffected.
10. Audit trail: `created_at`, `updated_at`, `created_by_user_id` on all records; link/unlink events logged.

## Non-Functional Requirements
- Token is immutable once generated — never regenerated for the same marketing code.
- Holding page must be professional and on-brand (not a Rails error page).
- Rate-limit `/m/:token` endpoint (Rack::Attack) to prevent scraping.
- Admin UI pages must not be accessible to non-`@mellow.menu` users (return 403 or redirect).

## Technical Notes

### Models / Migrations
- `create_marketing_qr_codes`: `token:string unique not null`, `status:integer default:0`, `holding_url:string`, `restaurant_id:bigint`, `menu_id:bigint`, `tablesetting_id:bigint`, `smartmenu_id:bigint`, `name:string`, `campaign:string`, `created_by_user_id:bigint not null`.
- Index: `[token]` (unique), `[status]`, `[restaurant_id]`.

### Services
- `app/services/marketing_qr_codes/link_service.rb`: handles Smartmenu find-or-create logic on linking. Idempotent.
- `app/services/marketing_qr_codes/resolve_service.rb`: resolves token to redirect destination.

### Policies
- `app/policies/marketing_qr_code_policy.rb`: allow all actions only if `user.email.ends_with?('@mellow.menu')`.

### Controllers
- `app/controllers/marketing_qr_codes_controller.rb` (public): `resolve` action only.
- `app/controllers/admin/marketing_qr_codes_controller.rb`: full CRUD + link/unlink/print actions.

### Views
- `app/views/marketing_qr_codes/holding.html.erb`: branded "Coming Soon" holding page.
- `app/views/admin/marketing_qr_codes/`: index, new, print (print-optimised layout).

### Routes
```ruby
get '/m/:token', to: 'marketing_qr_codes#resolve', as: :marketing_qr_code

namespace :admin do
  resources :marketing_qr_codes do
    member do
      patch :link
      patch :unlink
      get :print
    end
  end
end
```

### Flipper
- No Flipper flag needed — admin-only feature with email-domain gating.

## Acceptance Criteria
1. `GET /m/:valid_unlinked_token` renders the holding page (200) or redirects to `holding_url`.
2. `GET /m/:valid_linked_token` redirects (302) to the correct `/t/:public_token` SmartMenu URL.
3. `GET /m/:invalid_token` returns 404.
4. A non-`@mellow.menu` user cannot access `GET /admin/marketing_qr_codes` (returns 403 or redirect).
5. Linking a marketing QR code to a restaurant+menu+tablesetting creates or reuses the correct `Smartmenu` record (idempotent).
6. After unlinking, `GET /m/:token` returns to holding behaviour.
7. The print view renders a QR code encoding `https://mellow.menu/m/:token`.
8. `created_by_user_id` is populated on every created record.
9. Existing `/smartmenus/:slug` and `/t/:public_token` routes are unaffected by this feature.

## Out of Scope
- Bulk QR generation (post-launch).
- Campaign analytics (scan counts, geo breakdown) — post-launch.
- Self-serve QR generation by restaurant owners — admin-only in v1.
- Integration with print-on-demand services.

## Open Questions
1. What should the holding page say? Options: (a) "This restaurant is coming soon on mellow.menu", (b) a generic branded "Menu launching soon" page. Confirm with marketing.
2. Should the holding URL default to the mellow.menu marketing homepage, or a dedicated landing page?
3. Is `campaign` metadata required for v1, or can it be added post-launch?
