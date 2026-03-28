---
name: Theming via CSS custom properties and data-theme attributes
description: Smartmenu theming uses data-theme on <html> and CSS custom property overrides — same pattern as existing dark mode
type: project
---

Theme variants are implemented as named `data-theme` attribute values on the `<html>` tag, extending the existing `[data-theme="dark"]` dark-mode pattern. Each theme is a SCSS file that overrides CSS custom properties declared in `_smartmenu_mobile.scss` — no new CSS architecture or frontend framework.

**Why:** The dark-mode pattern is already proven in the codebase. Extending it avoids a parallel theming system and keeps all visual tokens in one property contract.

**How to apply:** When any future feature needs per-tenant or per-resource visual variation (colour, spacing, typography), reach for CSS custom properties + a `data-` attribute on `<html>` before proposing a new theming library or framework. The key risk in any theming work is auditing `_smartmenu_mobile.scss` (1500+ lines with a mix of custom properties and hard-coded values) — flag this audit as the highest-effort task in any theming spec.

Key decisions recorded in the Smartmenu Theming spec (2026-03-28):
- Theme scoped per `Smartmenu`, not per `Restaurant` (column on `smartmenus` table)
- Cache bust: `Rails.cache.delete_matched` called synchronously after `saved_change_to_theme?`; fragment cache keys also include `@smartmenu.theme` as belt-and-suspenders
- Preview endpoint: `GET smartmenus#preview?theme=<value>` renders the real layout in a sandboxed iframe — no DB write
- Google Fonts via CDN `<link>` in v1 (one font per theme); self-hosting deferred
- Dark mode and theming are orthogonal in v1; no dark variants of named themes required
- `params[:theme]` on the preview endpoint must be validated against `Smartmenu::THEMES` before use — never pass raw user input to `data-theme`
