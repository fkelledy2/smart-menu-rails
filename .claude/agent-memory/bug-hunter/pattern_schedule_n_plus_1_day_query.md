---
name: Schedule partial N+1 — 7 queries for menu availabilities
description: _schedule_2025 calls menu.menuavailabilities.where(dayofweek: day) inside a 7-iteration loop with no preload
type: project
---

In `_schedule_2025.html.erb` line 45:
```erb
<% day_availability = menu.menuavailabilities.where(dayofweek: day).order(:sequence).first %>
```

This runs inside `%w[monday tuesday wednesday thursday friday saturday sunday].each_with_index` (line 44), firing 7 separate DB queries. No `includes` or preload is done before the loop.

**Fix**: load all 7 records before the loop:
```erb
<% availabilities_by_day = menu.menuavailabilities.order(:sequence).group_by(&:dayofweek) %>
```
Then use `availabilities_by_day[day]&.first` inside the loop.

**File**: `app/views/menus/sections/_schedule_2025.html.erb` line 45
