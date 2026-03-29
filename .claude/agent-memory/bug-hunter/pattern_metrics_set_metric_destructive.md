---
name: MetricsController set_metric destructive before_action
description: set_metric before_action calls Metric.delete_all and seeds data on every edit/update/destroy — P1 data corruption and assignment-instead-of-comparison bug
type: project
---

MetricsController registers `before_action :set_metric, only: %i[edit update destroy]`.

Inside `set_metric` (line 97 onward):
- `Metric.delete_all` wipes the entire table on every page view
- Recreates a Metric from live counts
- Seeds Testimonials for all restaurants, including `if (restaurant.status = 'active')` which is an assignment (=), not comparison (==) — always truthy, mutates status in memory
- Seeds Features and Plans if none exist

**Why:** This is legacy scaffold seed code that was never removed. It runs as a before_action on every authenticated access to the metrics edit/update/destroy path.

**How to apply:** Fix by replacing set_metric with a simple `Metric.find(params[:id])`. The seeding should be a one-time rake/seed task. The assignment bug on line 109 is also a typo that must be corrected to `==`.
