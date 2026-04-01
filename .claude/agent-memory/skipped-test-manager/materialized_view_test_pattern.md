---
name: Materialized view test pattern for Smart Menu
description: Correct setup pattern for PostgreSQL materialized view tests — avoids DDL-in-transaction errors
type: feedback
---

## Problem
Materialized views are created by `structure.sql` but are never populated (`REFRESH MATERIALIZED VIEW` is not called). Tests that try to `SELECT` from an unpopulated view get `PG::ObjectNotInPrerequisiteState`. The old setup attempted `CREATE MATERIALIZED VIEW IF NOT EXISTS` inside a transaction — impossible for DDL.

## Solution
In `setup`, call `REFRESH MATERIALIZED VIEW <view_name>` first. If the view doesn't exist yet, fall back to CREATE. Use `rescue ActiveRecord::StatementInvalid` to catch the "not populated" error and redirect to the create path.

```ruby
def ensure_materialized_view_populated
  SomeMv.connection.execute('REFRESH MATERIALIZED VIEW some_mv')
rescue ActiveRecord::StatementInvalid
  create_test_materialized_view
end
```

**Why:** `REFRESH MATERIALIZED VIEW` works outside a transaction. It populates the view from current data (empty in test DB = empty result set, but queryable). `CREATE MATERIALIZED VIEW` is DDL and cannot run inside a Rails transaction.

**How to apply:** Any test file for a model backed by a materialized view (`DwOrdersMv`, `MenuPerformanceMv`, `RestaurantAnalyticsMv`) should use this pattern in `setup`.

## Files Fixed
- `test/models/menu_performance_mv_test.rb`
- `test/models/restaurant_analytics_mv_test.rb`
- `test/models/dw_orders_mv_test.rb`
