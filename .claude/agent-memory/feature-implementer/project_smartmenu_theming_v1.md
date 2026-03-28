---
name: Smartmenu Theming v1
description: Smartmenu Theming v1: data-theme vs data-color-scheme split, Smartmenus:: namespace, manifest.js gotcha, CSS theme architecture (March 2026)
type: project
---

Smartmenu Theming v1 shipped 2026-03-28. Three named themes: modern (default), rustic, elegant.

**Why:** High-visibility customer-facing feature, no dependencies, differentiates product.

**Key decisions:**

1. `data-theme` on `<html>` is now used for named restaurant themes (modern/rustic/elegant). `data-color-scheme` replaces the old `data-theme="dark"/"light"` for the dark/light toggle. These are orthogonal.

2. `theme_toggle_controller.js` was updated: localStorage key changed from `'theme'` to `'colorScheme'`; setAttribute calls changed from `data-theme` to `data-color-scheme`.

3. `_dark_mode.scss` selectors updated: `:root[data-theme="dark"]` → `:root[data-color-scheme="dark"]` and media query guard updated to match.

4. Service namespace: `Smartmenus::ThemeCacheBuster` (plural, module) not `Smartmenu::ThemeCacheBuster` — `Smartmenu` is a class, not a module, so `module Smartmenu` causes a `TypeError: Smartmenu is not a module`. Always use `Smartmenus::` (plural) for service modules.

5. Asset manifest gotcha: every new Stimulus controller JS file MUST be added to `app/assets/config/manifest.js` with `//= link controllers/<name>_controller.js`. Without this, `pin_all_from 'app/javascript/controllers'` in importmap causes "Asset not declared to be precompiled" errors in tests. Pre-existing controllers were failing too until the manifest entry was added.

6. Fragment cache keys in `show.html.erb` include `@smartmenu.theme` to ensure theme changes bust the fragment cache automatically (belt-and-suspenders alongside explicit `ThemeCacheBuster`).

7. Google Fonts CSP: added `'https://fonts.gstatic.com'` to `font_src` and `'https://fonts.googleapis.com'` to `style_src` in `config/initializers/content_security_policy.rb`.

8. Flipper flag `smartmenu_theming` gates the theme picker on the edit form. Flag disabled = form renders without the theme picker, so tests don't see it.

9. `preview` action on `SmartmenusController` uses `authorize sm, :show?` since `show?` returns `true` (public). The action just redirects to the public token URL.

**How to apply:** When adding named visual themes to any model-backed page: use `data-theme` for named themes, `data-color-scheme` for light/dark. Always declare new Stimulus controllers in manifest.js. Use `Smartmenus::` (plural) for service namespace.
