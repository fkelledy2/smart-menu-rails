---
name: Inline Style Abuse Pattern
description: 335 inline style occurrences across 81 view files; primarily hardcoded font-size px values and colour hex codes that bypass the design system
type: project
---

**Rule:** Inline styles are a maintenance liability and bypass both Bootstrap utilities and the 2025 design token system.

**Most common offenders:**
- font-size: 10px, 11px, 12px, 13px — should use Bootstrap .small, .fs-6, .text-xs, or .text-sm
- color: #6B7280, #9CA3AF etc. — should use .text-muted, .text-secondary, or CSS custom props
- Hardcoded layout values: style="max-width: 960px;" on container divs — should use Bootstrap max-width utilities or container variants
- style="width: 260px;" on Kanban columns — should be a CSS class
- letter-spacing: 0.08em + font-size: 11px repeated pattern for "column header" labels in CRM (index.html.erb, show.html.erb, notes)
- style="font-size: 13px;" appearing in 20+ places — define a CSS class or use Bootstrap .small

**Worst files (admin/crm/):** admin/crm/leads/show.html.erb (13 occurrences), admin/crm/leads/_card.html.erb (4 occurrences), admin/crm/audits/index.html.erb

**April 2026 fixes applied:**
- `style="max-width: Npx;"` on table cells → `mw-0` (with `text-truncate` on child div)
- `style="max-width: 200px;"` on form inputs → `w-auto`
- `style="min-width: 260px;"` on form inputs → removed (flexbox handles it)
- `style="max-width: 420px;"` on input-groups → removed
- `style="max-width: 200px;"` on cache warm field → `w-auto`
- `style="max-width: Npx;"` in agent workbench pre elements → `max-height: Nrem;`
- `style="font-size: 0.7rem;"` in menu_import_review → `small`
- `style="cursor: pointer;"` on `<summary>` elements → removed (native browser behaviour)
- `style="width:90px"` / `style="width:180px"` on form selects/fields → `w-auto`
- Tailwind classes in `edit_2025.html.erb` (`text-2xl`, `font-semibold`, `text-gray-900`) → Bootstrap `h3 fw-semibold`, `small text-muted`

**How to apply:** When editing any of these files, migrate inline font-size/color styles to Bootstrap utilities or 2025 token classes. For letter-spacing + text-transform patterns, extract a shared .label-overline or .section-label class in _cards_2025.scss.
