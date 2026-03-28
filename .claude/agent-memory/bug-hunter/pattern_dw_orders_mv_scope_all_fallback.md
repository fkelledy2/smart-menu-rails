---
name: DwOrdersMvPolicy scope.all cross-tenant fallback
description: DwOrdersMvPolicy::Scope#resolve returns scope.all when restaurant_id column is absent — cross-tenant analytics data leak
type: project
---

`DwOrdersMvPolicy::Scope#resolve` (app/policies/dw_orders_mv_policy.rb) checks `scope.column_names.include?('restaurant_id')`. If the column is absent, the else branch returns `scope.all` — every authenticated user sees all restaurants' order analytics.

Fix: replace `scope.all` with `scope.none` in the else branch (fail-safe). Add a super-admin branch if analysts need unrestricted access.

**Why:** The `scope.all` fallback was left as a "for now" placeholder and never replaced with a safe default.

**How to apply:** When investigating analytics data exposure or DwOrdersMv queries, check this policy. Also verify `dw_orders_mv` always includes `restaurant_id` after any materialized view rebuild.
