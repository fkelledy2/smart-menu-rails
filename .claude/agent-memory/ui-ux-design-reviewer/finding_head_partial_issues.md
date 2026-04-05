---
name: shared/_head.html.erb — title wiring, FontAwesome CDN, and inline style block
description: Three issues fixed in shared/_head.html.erb: content_for :title wired, FontAwesome CDN removed, large <style> block migrated to SCSS
type: project
---

**Issue 1 — content_for :title was never wired (fixed 2026-04-04)**

`shared/_head.html.erb` used `@page_title` (set in controllers) to render `<title>`. Views using `content_for :title` were doing nothing because the head partial never yielded it.

Fixed by adding at top of `_head.html.erb`:
```erb
<% _page_title = content_for?(:title) ? yield(:title) : @page_title.presence || t('shared.head.meta_title') %>
```
Both `<title>` and `<meta name="title">` now use `_page_title`.

**How to apply:** Use `content_for :title` in views as primary mechanism. Controller `@page_title` is now a fallback for views that haven't been migrated yet.

---

**Issue 2 — FontAwesome CDN still loaded in _head.html.erb (fixed 2026-04-04)**

Despite a prior pass removing all `fas fa-*` references from view files, `_head.html.erb` still loaded FontAwesome 6 via CDN for all non-smartmenu pages. Bootstrap Icons is already loaded from the npm package via `application.bootstrap.scss`. The CDN link was removed.

**How to apply:** Never add FontAwesome back. All new icons must use `bi bi-*` classes.

---

**Issue 3 — Large inline <style> block in _head.html.erb (fixed 2026-04-04)**

`_head.html.erb` contained ~125 lines of CSS in a `<style>` block loaded on every page. Included:
- `.btn-dark` override with a CSS syntax error (`525659` dangling token after `--bs-btn-bg: #525659;`)
- Tabulator footer styles
- `.rounded-video`, `.video-container`, `.background-container` (marketing page media)
- `.btn-allergyn-group-custom-rounded`, `.btn-order-group-*` (order UI button border-radius overrides)
- `.flag-icon`, `.flag-icon-selected` (locale selector icons)
- `#addItemToOrderImage` (order animation)

All migrated to SCSS:
- `btn-dark` → `_bootstrap_enhancements.scss` (syntax error fixed)
- Tabulator footer → `_tables.scss`
- All other classes → `_utilities.scss`

**Why:** Global `<style>` blocks in layout partials bypass the CSS pipeline, cannot be cached separately, and cause specificity issues.
