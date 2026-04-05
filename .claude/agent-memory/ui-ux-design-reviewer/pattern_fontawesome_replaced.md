---
name: FontAwesome fully replaced with Bootstrap Icons
description: fas fa-* references swept from all operator views 2026-04-04 — Bootstrap Icons is the only icon library used
type: project
---

All `fas fa-*` FontAwesome references have been replaced with Bootstrap Icons equivalents across:
- `shared/_analytics_dashboard.html.erb` (plus bare CDN `<script src="chart.js">` removed)
- `shared/_performance_charts.html.erb`
- `shared/_performance_kpis.html.erb`
- `shared/_performance_details_table.html.erb`
- `shared/_navbar.html.erb`
- `shared/_smartmenunavbar.html.erb`
- `onboarding/account_details.html.erb`
- `restaurants/analytics.html.erb`
- `restaurants/performance.html.erb`
- `menus/performance.html.erb`

The `icon` string parameter passed to `shared/_performance_dashboard` and `shared/_analytics_dashboard` should now use `bi bi-*` class strings, not `fas fa-*`.

**Why:** FontAwesome is not installed — these would silently render nothing. Bootstrap Icons is the project-wide standard (CDN loaded in `shared/_head`).

**How to apply:** Any new icon reference in operator views must use `bi bi-*` classes. Never introduce `fas`, `far`, or `fab` classes.
