---
name: Agent workbench views review status
description: restaurants/agent_workbench/ reviewed in April 2026 — clean Bootstrap 5 structure, a few minor issues fixed
type: project
---

The `restaurants/agent_workbench/` directory contains 6 operator views for the AI workflow feature (menu optimisation, growth digest, menu import review). Reviewed 2026-04-04.

**Architecture**: views use `py-3` (tighter than admin's `py-4`), `h4 fw-bold` headings (appropriate — these are subsections within the restaurant dashboard layout, not standalone admin pages). Bootstrap card + list-group patterns used consistently.

**Fixed in this session**:
- `data: { confirm: }` → `data: { turbo_confirm: }` in optimization.html.erb, digests.html.erb, menu_import_review.html.erb
- `style="max-height: 400px"` → `.mh-400` in optimization_review.html.erb
- `style="max-height: 12rem"` → `.mh-12rem` in show.html.erb
- `style="max-height: 9rem"` → `.mh-9rem` in show.html.erb
- `style="letter-spacing: .05em"` → `.ls-wide` in digests.html.erb (×2)
- `style="width: 200px"` removed from menu_import_review.html.erb rejection input (field now fills naturally in its flex container)

**Remaining acceptable inline styles**:
- `style="width: X%"` on progress-bar fills (dynamic %, cannot use utility classes)
- `style="width: 5rem; height: 6px;"` on progress container (very specific UI element — justified)

**UX note**: The optimization_review preview list uses `.overflow-y-auto.mh-400` — Bootstrap 5.3 `overflow-y-auto` is confirmed available (Bootstrap 5.3.3 in package.json).
