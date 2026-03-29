---
name: Restaurants::AnalyticsController invalid Ordr statuses and rand() stub
description: Analytics controller used non-existent status strings ('cancelled', 'open', 'pending') and rand() for fake traffic data (FIXED)
type: project
---

`app/controllers/restaurants/analytics_controller.rb` had two issues:

**1. Invalid Ordr status strings in collect_order_analytics_data:**
```ruby
# BEFORE (broken): none of these status strings exist on Ordr
cancelled: orders.where(status: 'cancelled').count,  # always 0
pending: orders.where(status: %w[open pending]).count,  # always 0
```
Ordr enum: `{ opened: 0, ordered: 20, preparing: 22, ready: 24, delivered: 25, billrequested: 30, paid: 35, closed: 40 }`. No `cancelled`, `open`, or `pending` states exist.

**2. rand() in generate_daily_traffic_data:**
```ruby
# BEFORE (broken): returns fake random data to the UI on every request
{ date: ..., value: rand(10..100) }
```
Traffic analytics are a TODO stub. Using `rand()` sends misleading numbers to dashboards. Fixed to return 0 consistently.

**Fix:** Use `Ordr.statuses.slice(...)` to get numeric values, return `0` for non-existent cancelled state, and return constant zeros for unimplemented traffic data.

**Why:** The analytics controller appears to have been scaffolded/stub-written and never aligned with the actual Ordr AASM states.

**How to apply:** Always reference `Ordr.statuses['status_name']` or `Ordr.statuses.slice(...)` when filtering by Ordr status. Never use raw string status values — the AASM enum maps strings to integers.
