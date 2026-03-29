---
name: Smartmenu Preview Modes
description: Replace the in-page staff/customer view toggle on /smartmenus with explicit preview launch links from the menu edit page, with mode locked for the duration of the preview session.
type: feature
status: implemented
priority: medium
---

# Smartmenu Preview Modes

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
