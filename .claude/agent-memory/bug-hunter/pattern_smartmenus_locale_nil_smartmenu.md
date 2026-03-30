---
name: SmartmenusLocaleController nil @smartmenu NoMethodError
description: update action called @smartmenu.menu.menuitems without nil guard after find_by lookup
type: feedback
---

`SmartmenusLocaleController#update` used `Smartmenu.where(slug:...).first` (which returns nil on unknown slug) then immediately called `@smartmenu.menu.menuitems` — NoMethodError `undefined method 'menu' for nil` on any invalid smartmenu_id.

**Fix:** Added nil guard `unless @smartmenu&.menu` with `head :not_found` and `return`.

**Why:** `where(...).first` never raises — it returns nil. Callers must always guard the result.

**How to apply:** Any use of `.where(...).first` (vs `.find_by` or `.find_by!`) must be guarded before dereferencing the result.
