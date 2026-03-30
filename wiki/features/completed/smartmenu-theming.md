# Feature Spec: Smartmenu Theming

## Status
- Priority Rank: #10
- Category: Launch Enhancer
- Effort: M
- Dependencies: None
- Flipper Flag: `smartmenu_theming`
- Created: 2026-03-28

---

## Overview

Restaurant owners can select a visual theme for their Smartmenu from a curated set of pre-built themes (Classic, Modern, Rustic, Elegant). Each theme controls the full visual language of the customer-facing menu: typography, colour palette, card shape, card layout, header/banner style, spacing/density, textures, icon style, and section dividers. Themes are scoped per `Smartmenu` (not per `Restaurant`) to allow multi-menu restaurants to differentiate their experiences. A live preview panel on the menu edit page shows the theme applied before committing the change, and every save immediately busts the fragment cache so customers see the new appearance without stale renders.

## Goals

- [ ] Restaurant owners can select from at least four named themes on the menu edit page
- [ ] A live preview panel renders the selected theme before the owner saves
- [ ] Theme is persisted on the `smartmenus` table and applied to the customer-facing Smartmenu layout at render time
- [ ] Theme change triggers immediate cache bust — no customer sees a stale appearance after an owner saves
- [ ] Each theme ships with one Google Font, loaded from CDN in v1
- [ ] All theme-controlled properties (colour, typography, spacing, shape, texture) are expressed as CSS custom properties, overriding the base values in `_smartmenu_mobile.scss`
- [ ] Success metric: restaurant owners can complete a theme change in under 60 seconds with zero page reloads during preview

## Non-Goals (Out of Scope for v1)

- Custom colour pickers or free-form theme editing (full white-labelling)
- Per-section or per-item overrides
- Dark mode interaction — dark mode is a separate, orthogonal toggle; themes apply within both light and dark mode
- More than four named themes at launch
- Self-hosted font pipeline (CDN acceptable in v1; self-hosting deferred)
- Theme scheduling (apply Theme A at lunch, Theme B at dinner)
- Theme versioning / rollback history
- Mobile app consideration (Smartmenu is web-only)

---

## User Stories

**As a restaurant owner**, I want to select a visual theme for my Smartmenu so that the customer-facing menu matches my restaurant's brand and atmosphere.

**As a restaurant owner**, I want to preview a theme before saving so that I can compare options without affecting what customers see in real time.

**As a customer**, I want the Smartmenu to load with the restaurant's chosen visual style immediately so that the experience feels intentional and branded from first render.

**As a restaurant owner**, I want to change the theme at any time and have the change take effect immediately for all customers so that I am never locked into a style I no longer want.

---

## Technical Design

### Architecture Notes

Themes are implemented as named `data-theme` attribute values on the `<html>` tag, extending the existing dark-mode pattern (`[data-theme="dark"]`). The Smartmenu layout file (`app/views/layouts/smartmenu.html.erb` or equivalent) is the correct injection point for the theme attribute — it already controls the `<html>` element.

Each theme is a SCSS file (e.g., `_theme_modern.scss`) that overrides the CSS custom properties declared in `_smartmenu_mobile.scss`. No existing CSS is removed; themes layer on top via specificity (`[data-theme="modern"] { --sm-primary: ...; }`). A `@font-face` or Google Fonts CDN `<link>` is conditionally rendered per theme in the layout head partial.

Theme selection UI lives on `restaurants/{id}/menus/{id}/edit` (existing page). A new partial renders the theme picker as a set of visual swatches. Selecting a swatch updates a hidden form field and injects the `data-theme` attribute onto the preview iframe (or a preview panel component) via a Stimulus controller — no round-trip to the server required for preview.

On save, the theme value is written to `smartmenus.theme`. A `Smartmenu::ThemeCacheBuster` service calls `Rails.cache.delete_matched` scoped to the affected smartmenu's cache key namespace. Fragment cache keys in `show.html.erb` must include `@smartmenu.theme` so that a theme change automatically generates a new key (belt-and-suspenders alongside the explicit bust).

### New Dependencies

No new gems required. Google Fonts loaded via CDN `<link>` tag conditionally rendered in the layout head. SCSS theme files use the existing Sass + esbuild pipeline. No additional npm packages required — Stimulus is already present.

### Data Model Changes

- [ ] Migration: add `theme` (string, default: `'classic'`, null: false) to `smartmenus`
- [ ] Index: none required — `theme` is a scalar attribute read on every smartmenu render; no query filtering by theme needed
- [ ] Validation: `validates :theme, inclusion: { in: %w[classic modern rustic elegant] }` on `Smartmenu`
- [ ] Policy: no new policy file required — theme write is governed by the existing `SmartmenuPolicy` (owner-scoped); add `theme` to permitted params in the existing `SmartmenusController`

### Service Objects

- [ ] `app/services/smartmenu/theme_cache_buster.rb` — accepts a `Smartmenu` instance; calls `Rails.cache.delete_matched` to invalidate all fragment cache entries keyed on that smartmenu; called synchronously from `SmartmenusController#update` after a successful save when theme has changed

No additional service objects required. Theme selection is a simple attribute write; no async processing or external calls are needed.

### Background Jobs

N/A. Cache bust is synchronous and fast (Redis `SCAN` + `DEL`). No background job warranted.

### Controllers & Routes

- [ ] No new routes required. Theme is an additional permitted param on the existing `PATCH /restaurants/:restaurant_id/menus/:menu_id/smartmenus/:id` route (or equivalent `SmartmenusController#update` action)
- [ ] Controller: `app/controllers/smartmenus_controller.rb` (existing) — add `theme` to `smartmenu_params`; after successful save, call `Smartmenu::ThemeCacheBuster.new(smartmenu).call` if `smartmenu.saved_change_to_theme?`
- [ ] Pundit: existing `authorize @smartmenu` in `#update` already covers this; no additional policy change required

New route for live preview data (if preview uses a server-rendered iframe):

- [ ] Route: `GET /restaurants/:restaurant_id/menus/:menu_id/smartmenus/:id/preview` → `smartmenus#preview` — renders the Smartmenu show view with a `?theme=` param overriding the persisted theme for preview only; no write to the database; protected by existing Pundit policy
- [ ] This endpoint is called by the Stimulus preview controller when the owner selects a swatch; it loads inside a sandboxed `<iframe>` in the edit page sidebar

### Frontend

- [ ] Stimulus controller: `app/javascript/controllers/theme_picker_controller.js`
  - Targets: swatch buttons, hidden `theme` input, preview iframe
  - On swatch click: updates hidden input value, sets `data-theme` on the iframe `<html>` if using inline preview, or reloads the preview iframe `src` with `?theme=selected_value`
  - Active swatch state managed via CSS class toggle (`theme-swatch--active`)
- [ ] Partial: `app/views/smartmenus/_theme_picker.html.erb` — renders swatch grid; each swatch shows a thumbnail preview image, theme name, and font sample; connected to `theme_picker_controller`
- [ ] Preview panel: a sandboxed `<iframe>` in the edit page layout pointing at `smartmenus#preview`; updates on swatch selection without a full page reload
- [ ] Layout injection: `app/views/layouts/smartmenu.html.erb` (or the equivalent Smartmenu layout) — read `@smartmenu.theme` (or `params[:theme]` on the preview endpoint) and set `data-theme="<theme>"` on `<html>`; conditionally render the Google Font CDN `<link>` for the active theme
- [ ] SCSS files (one per theme):
  - `app/assets/stylesheets/smartmenu/themes/_theme_classic.scss` — base theme (matches current appearance; effectively a no-op override, documents the custom property set)
  - `app/assets/stylesheets/smartmenu/themes/_theme_modern.scss` — clean lines, Inter font, reduced border radius, high-contrast palette
  - `app/assets/stylesheets/smartmenu/themes/_theme_rustic.scss` — warm tones, Playfair Display font, organic card shapes, textured dividers
  - `app/assets/stylesheets/smartmenu/themes/_theme_elegant.scss` — serif typography (Cormorant Garamond), restrained palette, generous whitespace, fine-rule dividers
  - Imported into the Smartmenu Sass manifest after `_smartmenu_mobile.scss`
- [ ] Swatch thumbnail images: static PNGs or SVGs in `app/assets/images/themes/` — one per theme, used in the picker UI

### CSS Custom Property Contracts

Each theme must override the following properties (drawn from the base declarations in `_smartmenu_mobile.scss`). This list is the agreed contract between the design pass and the engineering implementation:

| Property Group | Custom Properties |
|----------------|-------------------|
| Colour — brand | `--sm-primary`, `--sm-primary-hover`, `--sm-secondary`, `--sm-accent` |
| Colour — surfaces | `--sm-bg`, `--sm-card-bg`, `--sm-section-bg`, `--sm-divider-color` |
| Colour — text | `--sm-text-primary`, `--sm-text-secondary`, `--sm-text-muted` |
| Typography | `--sm-font-family-base`, `--sm-font-family-heading`, `--sm-font-size-base`, `--sm-line-height-base`, `--sm-heading-weight` |
| Shape | `--sm-card-radius`, `--sm-button-radius`, `--sm-badge-radius` |
| Spacing | `--sm-section-gap`, `--sm-card-gap`, `--sm-card-padding` |
| Shadows | `--sm-card-shadow`, `--sm-card-shadow-hover` |
| Dividers / Texture | `--sm-divider-style`, `--sm-section-divider-height`, `--sm-texture-url` |

Any `_smartmenu_mobile.scss` properties not yet expressed as custom properties must be refactored to use them as part of this feature's implementation.

### API / Webhooks

N/A. No external API or webhook required.

---

## Security & Authorization

- [ ] Pundit: existing `SmartmenuPolicy#update?` governs theme writes — owner-scoped, no change required
- [ ] Preview endpoint (`smartmenus#preview`) must also be authorized via Pundit — owner must own the restaurant that owns the smartmenu; no unauthenticated preview access
- [ ] `params[:theme]` on the preview endpoint must be validated against the permitted theme list before use (`Smartmenu::THEMES.include?(params[:theme])`) — never pass raw user input to `data-theme`; a malicious value could inject arbitrary attribute content
- [ ] Tenant scoping: `@smartmenu` is always loaded via `@restaurant.smartmenus.find(params[:id])` — existing tenant scoping applies
- [ ] Rack::Attack: preview endpoint is behind authentication, not public-facing — standard rate limiting applies; no additional rule needed
- [ ] Brakeman scan clean
- [ ] No PCI or GDPR implications — theme is presentation-only data

---

## Testing Plan

- [ ] Model spec `test/models/smartmenu_test.rb` — validates `theme` inclusion; rejects invalid values; defaults to `'classic'`
- [ ] Service spec `test/services/smartmenu/theme_cache_buster_test.rb` — asserts `Rails.cache.delete_matched` is called with the correct key pattern when `call` is invoked; asserts no cache operation occurs when theme has not changed
- [ ] Controller/request spec `test/controllers/smartmenus_controller_test.rb`:
  - PATCH with valid theme value saves and triggers cache bust
  - PATCH with invalid theme value returns 422 (or re-renders form with error)
  - GET preview with valid `?theme=` param renders 200 for authorized owner
  - GET preview with invalid `?theme=` param falls back to `'classic'` or returns 400
  - GET preview for a smartmenu not owned by the authenticated user returns 403
- [ ] System test `test/system/smartmenu_theming_test.rb`:
  - Owner can open edit page, see theme picker, click a swatch, see the preview iframe update, save, and have the Smartmenu render with the new theme
  - Classic theme is pre-selected for a smartmenu with no explicit theme set
- [ ] Edge cases:
  - Smartmenu with `theme: nil` (pre-migration rows) renders `'classic'` without error
  - Cache bust called only once per save even if theme is updated alongside other fields
  - Preview endpoint ignores theme param when user is not authorized (falls through to Pundit 403)
- [ ] Run: `bin/fast_test` — all passing

---

## Implementation Checklist

### Setup
- [ ] Feature flag created in Flipper: `smartmenu_theming`
- [ ] Migration: `add_theme_to_smartmenus` — add `theme string not null default 'classic'`; add check constraint `smartmenus_theme_check` to enforce allowed values at the DB level

### Core Implementation
- [ ] `Smartmenu::THEMES = %w[classic modern rustic elegant].freeze` constant on the model
- [ ] `validates :theme, inclusion: { in: THEMES }` on `Smartmenu`
- [ ] `theme` added to `smartmenu_params` in `SmartmenusController`
- [ ] `Smartmenu::ThemeCacheBuster` service implemented
- [ ] Cache bust called in `SmartmenusController#update` on `saved_change_to_theme?`
- [ ] Preview route + `smartmenus#preview` action added and authorized
- [ ] Fragment cache keys in `show.html.erb` (and any sub-partials with independent keys) updated to include `@smartmenu.theme`

### SCSS / CSS
- [ ] Audit `_smartmenu_mobile.scss` — identify all hard-coded colour, font, spacing, shape, and shadow values; extract them to CSS custom properties in a `:root` / base block
- [ ] Write `_theme_classic.scss` (documents the property set; current values)
- [ ] Write `_theme_modern.scss`
- [ ] Write `_theme_rustic.scss`
- [ ] Write `_theme_elegant.scss`
- [ ] Import all four theme files in the Smartmenu Sass manifest after the base stylesheet
- [ ] Verify Sass compiles without errors (`yarn build:css` or equivalent)

### Frontend
- [ ] Swatch thumbnail assets created and committed to `app/assets/images/themes/`
- [ ] `_theme_picker.html.erb` partial built with swatch grid
- [ ] `theme_picker_controller.js` Stimulus controller written and connected
- [ ] Preview iframe wired up in edit page layout
- [ ] Google Font CDN `<link>` conditionally rendered per theme in Smartmenu layout head
- [ ] `data-theme` attribute set on `<html>` from `@smartmenu.theme` in layout
- [ ] Mobile/responsive verified — theme picker swatches usable on small screens

### Quality
- [ ] All tests written and passing (`bin/fast_test`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Brakeman clean (`bundle exec brakeman`)
- [ ] JS/CSS lint clean (`yarn lint`)
- [ ] Docs regenerated (`bin/generate_docs`)
- [ ] Manual smoke test: cycle through all four themes, save each, confirm customer-facing Smartmenu reflects changes with no stale cache render

### Release
- [ ] Feature flag `smartmenu_theming` enabled for internal accounts first; roll out to all restaurants once QA sign-off received
- [ ] Migration is safe for zero-downtime deploy — adding a column with a default and a check constraint is non-blocking on PostgreSQL 14+; no lock contention expected
- [ ] Monitor Sidekiq / Redis for any unexpected cache bust volume spikes on rollout day

---

## Open Questions

1. **CSS custom property audit scope**: `_smartmenu_mobile.scss` is 1500+ lines with a mix of custom properties and hard-coded values. The audit to extract all hard-coded values into overrideable properties is the highest-risk task in this spec — it touches every visual element of the customer-facing menu. A dedicated design-engineering pairing session to agree the full property list before implementation begins is strongly recommended.
2. **Swatch thumbnail assets**: Who produces the theme thumbnail images used in the picker? If design resources are unavailable, a CSS-only swatch (showing the theme's primary colour and font sample) is an acceptable v1 substitute and removes the asset-production dependency.
3. **Preview iframe vs inline preview**: A sandboxed `<iframe>` pointing at `smartmenus#preview` is the most faithful preview mechanism (it renders the real layout + CSS), but adds a network round-trip on each swatch click. An alternative is a CSS-only preview that applies the `data-theme` attribute to an inline div mocking the card structure. The iframe approach is recommended for fidelity; the inline approach is faster to build. Decision needed before frontend sprint begins.
4. **Google Fonts CSP**: If a Content Security Policy header is set on the Smartmenu layout, the CDN `<link>` for Google Fonts requires `style-src fonts.googleapis.com` and `font-src fonts.gstatic.com`. Confirm whether a CSP is in place and update it accordingly.
5. **Dark mode interaction**: When a customer has `data-theme="dark"` active alongside a restaurant's chosen theme (e.g., `data-theme="rustic"`), only one `data-theme` value can sit on `<html>` at once. Confirm whether dark mode and theming should be additive (requiring a different signal, e.g., a `data-color-scheme` attribute for dark mode) or whether dark variants of each theme are out of scope for v1. Assumption: dark mode and theming are orthogonal in v1 — dark mode overrides theme colour properties; no dark variants of named themes are required.

## References

- Existing dark mode implementation: `[data-theme="dark"]` on `<html>` in the Smartmenu layout
- Primary stylesheet: `app/assets/stylesheets/smartmenu/_smartmenu_mobile.scss` (1500+ lines)
- Fragment cache keys: `app/views/smartmenus/show.html.erb` (keyed on `[@smartmenu, @menu, @restaurant, ...]`)
- `Smartmenu` model: `app/models/smartmenu.rb`
- Priority Index: `docs/features/todo/PRIORITY_INDEX.md`
