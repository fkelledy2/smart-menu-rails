---
name: btn-xs Bootstrap 4 legacy class
description: btn-xs is a Bootstrap 4 class removed in Bootstrap 5; 9 instances found across profitability section partials in April 2026
type: project
---

`btn-xs` does not exist in Bootstrap 5 — it renders the button without any size modifier. The Bootstrap 5 equivalent is `btn-sm`.

As of 2026-04-04, instances were found in:
- `restaurants/sections/_profitability_targets_2025.html.erb` (fixed)
- `restaurants/sections/_profitability_margins_2025.html.erb` (fixed)
- `restaurants/sections/_profitability_ingredients_2025.html.erb` (fixed)
- `profit_margin_targets/index.html.erb` (fixed)
- `menus/sections/_profitability_2025.html.erb` (fixed)

All fixed in this session. These were originally scaffolded from an older Bootstrap 4-era template and not updated when Bootstrap 5 was adopted.

**Why:** btn-xs silently does nothing in Bootstrap 5 — the button renders at default size, which is oversized in tight table rows.
**How to apply:** When reviewing profitability or ingredient views, confirm all btn-xs have been converted to btn-sm.
