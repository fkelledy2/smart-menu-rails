---
name: Smartmenu Preview Modes
description: Replace the in-page staff/customer view toggle on /smartmenus with signed token-based preview launch from the menu edit page, with mode locked for the session.
type: feature
status: spec-ready
priority: medium
refined: true
priority_rank: 36
---

# Smartmenu Preview Modes

## Status
- Priority Rank: #36
- Category: Launch Enhancer
- Effort: S
- Dependencies: None (SmartMenu routes and views already exist; Rails `message_verifier` built in)
- Refined: true

## Problem Statement

The current `/smartmenus` page renders a floating `staff-mode-indicator` banner for any authenticated user, offering an in-page toggle between Staff view and Customer view. This is architecturally wrong and cosmetically harmful: the customer-facing smartmenu URL should unconditionally render as a customer experience. Staff previewing the menu can accidentally toggle mode and lose context, and any real customer visiting the URL while logged in sees an intrusive staff UI element. Mode selection belongs at the launch point — the menu edit page — not inside the customer experience.

## Success Criteria

- All preview mode selection happens on the menu edit page; no in-page mode toggle exists on `/smartmenus`
- The `staff-mode-indicator` div is completely removed from `smartmenus/show.html.erb`
- Staff preview: authenticated session preserved; staff controls visible
- Customer preview: `current_user` treated as nil for smartmenu rendering only (no sign-out); staff controls absent
- Preview mode is locked for the duration of a signed URL token (4 hours); refreshing preserves mode
- Expired or tampered tokens degrade gracefully to customer view (no 500 error)

## User Stories

- As a restaurant manager, I want to launch a staff preview of my smartmenu from the edit page and see exactly what staff see, without any risk of accidentally switching to customer view mid-preview.
- As a restaurant manager, I want to launch a customer preview from the edit page and see exactly what a real customer sees — no staff controls, no session artifacts.
- As a customer visiting the smartmenu URL, I want to see a clean customer experience regardless of whether I happen to be logged in to mellow.menu.

## Functional Requirements

1. Remove the `staff-mode-indicator` block (`lines 27–51` of `app/views/smartmenus/show.html.erb`) entirely.
2. Create `app/models/smartmenu_preview_token.rb` — a plain Ruby class (not ActiveRecord) with `generate(mode:, menu_id:)` and `decode(token)` using `Rails.application.message_verifier(:smartmenu_preview)`. TTL: 4 hours. Return `nil` on expired or tampered tokens.
3. Update `SmartmenusController` mode detection: if `params[:preview]` is present, decode the token and set `@staff_view_mode` from the payload. If no token or invalid token, default to customer view (`@staff_view_mode = false`). Remove all `params[:view]` logic.
4. Update the preview launch buttons on the menu edit page to generate signed tokens server-side and embed them in the href. Both buttons should open in a new tab (`target: '_blank'`).
5. Keep the legacy `?view=staff` param functional for one release with a Rails deprecation log warning; remove entirely in the following release.
6. No ActionCable channel changes are required for Phase 1: customer preview simply does not establish an authenticated channel (the WebSocket connect guard already requires `current_user`).

## Non-Functional Requirements

- Token signing must use `Rails.application.message_verifier` — no custom crypto, no JWT, no new gem
- Expired token fallback must render HTTP 200 (customer view), not 422 or 500
- The `menu_id` in the token must be validated against the restaurant's menus on decode to prevent cross-restaurant token reuse
- No session mutation: the override of `current_user` is local to smartmenu rendering only

## Technical Notes

- New plain Ruby class: `app/models/smartmenu_preview_token.rb` (no migration, no Pundit policy needed)
- Modify: `app/controllers/smartmenus_controller.rb` — replace `params[:view]` check with token decode logic
- Modify: preview button partials in `app/views/menus/sections/_details_2025.html.erb`
- Remove: `staff-mode-indicator` block in `app/views/smartmenus/show.html.erb`
- Flipper flag: `smartmenu_preview_tokens` — gate the new token path while `?view=staff` deprecation window runs
- No new Sidekiq jobs, no new DB tables, no new ActionCable channels

## Acceptance Criteria

1. A logged-in user visiting `/t/{slug}` directly (no preview param) sees no staff controls and no mode-toggle indicator — identical to an unauthenticated customer view.
2. Clicking "Preview as Staff" on the edit page opens a new tab with a signed token URL; staff controls are visible; no mode-toggle indicator is rendered.
3. Clicking "Preview as Customer" on the edit page opens a new tab with a signed token URL; staff controls are absent; `current_user` is treated as nil for rendering; no mode-toggle indicator is rendered.
4. An expired token (simulated by advancing time past TTL) renders as customer view without any error.
5. A tampered token (modified payload) renders as customer view without any 500 error.
6. The `staff-mode-indicator` div is absent from rendered HTML in all scenarios (staff preview, customer preview, direct URL, unauthenticated).
7. The `?view=staff` param still functions (with a deprecation log line) for one release.

## Out of Scope

- Per-tab session isolation (cookies are shared across tabs — ruled out; token-in-URL is the correct approach)
- Pretender-based guest impersonation (requires a dummy user record; fragile — ruled out)
- ActionCable channel override for customer preview (Phase 2 concern; document in open questions)
- Token-in-session storage (sharing the URL giving others a preview is acceptable given the 4h TTL)

## Open Questions

1. **Q1 — Legacy `?view=staff` grace period**: One release or immediate removal? Recommendation: one release with deprecation log, then hard remove.
2. **Q2 — "Back to edit" link in staff preview**: Should the staff preview show a small "Back to edit" pill (visible only in staff preview mode) to allow quick navigation back? Or is opening in a new tab (`target: _blank`) sufficient?
3. **Q3 — ActionCable in customer preview**: When a logged-in user views the customer preview, the WebSocket connection re-authenticates via cookie and may see staff-level channel data. Should the preview token be passed to the ActionCable connection, or is no-channel-in-customer-preview the correct Phase 1 approach?
4. **Q4 — Token expiry UX**: After 4 hours the URL silently degrades to customer view. Should there be a visible "Preview session expired — relaunch from edit page" notice, or silent fallback?

## Problem

The current `/smartmenus` page shows a `staff-mode-indicator` banner to any logged-in user, offering a one-click toggle between "Staff view" and "Customer view". This is:

1. **Visually intrusive** — a floating indicator on the customer-facing URL is not production-appropriate.
2. **Confusing** — staff previewing the menu can accidentally switch modes and lose context.
3. **Architecturally leaky** — the customer-facing `/t/{token}` URL should be unconditionally customer-mode; mode selection belongs at the launch point (the edit page), not inside the customer experience.

## Goals

1. Launch both staff and customer previews from `/restaurants/:id/menus/:id/edit` (already partially exists via quick-action buttons — needs to be the *only* entry point for mode selection).
2. Once in a preview mode, that mode is locked for the session — no in-page switching.
3. Remove the `staff-mode-indicator` toggle from `/smartmenus` entirely.
4. Staff mode = authenticated user with explicit staff preview context. Customer mode = the smartmenu renders as if there is no authenticated user (no staff controls, no session-aware ordering state tied to a staff account).

## Current Implementation Notes

- `@staff_view_mode = current_user.present? && params[:view] == 'staff'` (controller line 457)
- The edit page already has "Preview as Staff" (`smartmenu_path(slug)`) and "Preview as Customer" (`smartmenu_path(slug, view: 'customer')`) quick-action buttons opening in a new tab.
- The `staff-mode-indicator` is rendered on every page load when `current_user.present?`, regardless of which tab opened the preview.
- Pretender gem is available for user impersonation but does **not** support impersonating a nil/guest user — it requires a target User record.

## Proposed Approach

### Option A — Signed preview token in URL (recommended)

Add a signed, short-lived URL parameter `?preview=<signed_token>` where the token encodes `{ mode: 'staff'|'customer', menu_id: X, expires_at: T }`.

- **Staff preview**: token encodes `mode: staff`. Controller checks token, sets `@staff_view_mode = true`, renders with staff controls. `current_user` is still available normally.
- **Customer preview**: token encodes `mode: customer`. Controller checks token, **overrides `current_user` to nil for smartmenu rendering only** (does not sign out the user). No staff controls are rendered; the experience is identical to an unauthenticated customer.
- Token is signed with `Rails.application.message_verifier`, expires after e.g. 4 hours.
- On refresh, the token is re-validated — mode is preserved as long as the token is valid.
- Remove `params[:view]` entirely — all mode selection goes through the token.

**Pros:** Mode is cryptographically tied to the URL; no session mutation; works across tabs; survives page refresh; forgeable tokens rejected.
**Cons:** URL is long; token expiry means a very long preview session eventually loses mode lock (falls back to default customer view, which is safe).

### Option B — Preview session cookie per-tab (not feasible)

Cookies are shared across all tabs in the same browser session. Per-tab isolation is not achievable with cookies. Ruled out.

### Option C — Use Pretender to impersonate a guest User record

Create a dedicated `guest_preview` User with no privileges. Pretender impersonates this user for customer previews. On navigating away, impersonation ends.

**Cons:** Requires a persistent dummy user record; Pretender's stop mechanism requires a redirect; fragile if guest user is deleted; not multi-tab safe (impersonation is session-wide, affecting all tabs). Ruled out.

### Recommended: Option A

## Changes Required

### 1. Remove `staff-mode-indicator` from `/smartmenus`

Delete the `<% if current_user %>...<div class="staff-mode-indicator">...</div>...<% end %>` block from `app/views/smartmenus/show.html.erb` lines 27–51.

### 2. Add signed preview token generation

```ruby
# app/models/smartmenu_preview_token.rb  (new)
class SmartmenuPreviewToken
  TTL = 4.hours

  def self.generate(mode:, menu_id:)
    payload = { mode: mode.to_s, menu_id: menu_id, exp: TTL.from_now.to_i }
    Rails.application.message_verifier(:smartmenu_preview).generate(payload)
  end

  def self.decode(token)
    payload = Rails.application.message_verifier(:smartmenu_preview).verify(token)
    return nil if payload[:exp] < Time.current.to_i
    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
```

### 3. Update controller mode detection

```ruby
# app/controllers/smartmenus_controller.rb
preview = params[:preview].present? ? SmartmenuPreviewToken.decode(params[:preview]) : nil

if preview
  @staff_view_mode = preview[:mode] == 'staff'
  @preview_mode_active = true  # suppresses any future toggle rendering
else
  # Legacy / direct URL: default to customer view; staff view requires explicit token
  @staff_view_mode = false
  @preview_mode_active = false
end
```

> **Open question Q1:** Should the legacy `?view=staff` param be kept as a fallback during transition, or removed immediately? Removing it is cleaner but may break any bookmarked or shared staff preview links.

### 4. Update preview launch links on the edit page

`app/views/menus/sections/_details_2025.html.erb` already has preview buttons. Update them to generate signed tokens:

```erb
<%= link_to smartmenu_path(slug, preview: SmartmenuPreviewToken.generate(mode: :staff, menu_id: menu.id)),
    target: '_blank', ... %>

<%= link_to smartmenu_path(slug, preview: SmartmenuPreviewToken.generate(mode: :customer, menu_id: menu.id)),
    target: '_blank', ... %>
```

### 5. Optional: "Back to edit" escape hatch

> **Open question Q2:** Should the staff preview show a small, unobtrusive "← Back to edit" link (not a mode toggle — just navigation back to the edit page)? This would be useful for the staff preview workflow without cluttering the customer view.

---

## Open Questions

**Q1 — Legacy `?view=staff` param**
Keep as fallback or remove immediately? Removing is cleaner; keeping allows a grace period for any bookmarked links. Recommendation: keep for one release, log a deprecation warning, then remove.

**Q2 — "Back to edit" link in staff preview**
Staff opening a preview from the edit page may want to navigate back. Should the staff preview show a minimal back-link (e.g. a floating `← Edit menu` pill in the top corner, not visible to real customers)? Or is opening in a new tab (`target: _blank`) sufficient — just close the tab?

**Q3 — Customer preview while logged in: how deep does the override go?**
With Option A, `current_user` is overridden to nil for smartmenu rendering. Does this need to propagate into ActionCable channels too (e.g. `UserChannel`, `KitchenChannel`)? If the preview opens a WebSocket connection it may re-authenticate via the cookie and see staff-level channel data even in customer mode. Should the preview token be passed to the cable connection, or should customer preview simply not establish any authenticated channel?

**Q4 — Token in URL vs token in session**
The proposed approach puts the token in the URL. This means sharing or copying the URL gives someone else a time-limited customer or staff preview. Is that acceptable, or should the token be stored in the session (tab-isolated via a `window.name` trick or similar) so it cannot be shared?

**Q5 — Token expiry UX**
After 4 hours, the token expires and the URL falls back to default (customer view). Should the page show a "Your preview session has expired — relaunch from the edit page" notice? Or silently fall back?

---

## Proposed Test Set

### Unit tests
- `SmartmenuPreviewToken.generate` returns a verifiable token with correct mode and menu_id
- `SmartmenuPreviewToken.decode` returns nil for expired tokens
- `SmartmenuPreviewToken.decode` returns nil for tampered tokens
- `SmartmenuPreviewToken.decode` returns the payload for valid tokens

### Controller tests (`smartmenus_controller_test.rb`)
- Staff preview token → `@staff_view_mode` is true
- Customer preview token → `@staff_view_mode` is false, `current_user` treated as nil for rendering
- No token → `@staff_view_mode` is false (default customer view)
- Expired token → `@staff_view_mode` is false (graceful fallback)
- Tampered token → 400 or graceful fallback (no 500)

### System tests
- Logged-in user opens staff preview via edit page → staff controls visible, no mode-toggle indicator
- Logged-in user opens customer preview via edit page → staff controls absent, no mode-toggle indicator
- Direct `/t/{token}` URL (no preview param, logged-in user) → customer view, no mode-toggle indicator
- Staff preview link opens in new tab and does not affect original edit page session
- After token expiry → page renders as customer view without error

### View tests
- `staff-mode-indicator` div is absent from rendered HTML regardless of `current_user` and preview params
- Staff preview: staff-only controls (e.g. locale selector, ordering management) are present
- Customer preview: staff-only controls are absent
