---
name: Inline style blocks in 2025 edit views
description: sizes/edit, tips/edit, allergyns/edit had identical embedded <style> blocks for .text-2xl, .text-gray-*, .text-sm — removed 2026-04-04
type: project
---

`sizes/edit.html.erb`, `tips/edit.html.erb`, and `allergyns/edit.html.erb` all contained identical trailing `<style>` blocks defining:
- `.text-2xl { font-size: 1.5rem; line-height: 2rem; }`
- `.text-gray-900 { color: var(--color-gray-900); }`
- `.text-gray-500 { color: var(--color-gray-500); }`
- `.text-sm { font-size: 0.875rem; }`

These are Tailwind-inspired utility names that duplicate existing Bootstrap utilities (`h3`, `text-muted`, `small`). All three files also used `link_to method: :delete` (broken in Turbo) and Tailwind-ish custom breadcrumb markup.

**Fixed 2026-04-04:**
- All three `<style>` blocks removed
- Breadcrumbs converted to Bootstrap 5 `<nav aria-label="breadcrumb"><ol class="breadcrumb">` pattern
- `link_to method: :delete` converted to `button_to data: { turbo_confirm: }`
- `h1.text-2xl.font-semibold` replaced with `h1.h3.fw-semibold`

**Why:** Page-scoped style blocks increase specificity unpredictably and resist theming. Bootstrap utilities should be used instead.
**How to apply:** If you see `.text-2xl`, `.text-gray-*`, `.font-semibold` classes in ERB, they are Tailwind-isms — replace with Bootstrap h-classes and fw-* utilities.
