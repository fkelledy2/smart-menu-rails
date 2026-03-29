---
name: pattern_menuitem_margin_status_missing
description: Menuitem#margin_status called in ProfitMarginAnalyticsService and two views but never defined — NoMethodError on every profit margin dashboard request
type: feedback
---

`ProfitMarginAnalyticsService#count_by_status` calls `mi.margin_status` and two views (`_showProfitMargins.html.erb`, `profit_margins/report.html.erb`) also call it, but `Menuitem` had no `margin_status` method defined.

**Why:** The method was likely planned but never implemented. It depends on `profit_margin_target` (has_one) and `profit_margin_percentage`.

**Fix:** Added `margin_status` to `Menuitem` — returns `'no_target'` when no `ProfitMarginTarget` exists, `'critical'` when below minimum, `'above_target'` when at or above target, `'below_target'` otherwise.

**How to apply:** When the profit margin analytics dashboard or report view raises `NoMethodError`, check that `Menuitem` has all methods called from `ProfitMarginAnalyticsService`.
