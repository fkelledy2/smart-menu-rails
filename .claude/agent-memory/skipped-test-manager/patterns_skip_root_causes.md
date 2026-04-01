---
name: Common skip root causes in Smart Menu test suite
description: Patterns found when auditing all skipped tests in April 2026 — root causes and resolution status
type: project
---

## Audit Date: 2026-04-01

### Patterns Found

**1. Conditional skip via `respond_to?` — always false (tests never actually skip)**
Files: `test/models/concerns/l2_cacheable_test.rb`, `test/services/advanced_cache_service_test.rb`, `test/services/menu_version_apply_service_test.rb`, `test/performance/perf_audit_2026b_test.rb`, `test/services/pricing/model_compiler_test.rb`
Verdict: These `skip unless method_exists` guards were stale safety nets. The methods all exist. Tests run and pass. No action needed.

**2. Fixture data gap — test checks for data that isn't in fixtures**
Files: `test/policies/customer_wait_queue_policy_test.rb` (users(:two) has no Employee record), `test/services/wait_time/estimation_service_test.rb` (restaurants(:two) has no tablesettings)
Fix: Corrected fixture reference to `users(:employee_staff)` and added `restaurant_two_table` fixture.

**3. Materialized view not populated in test DB**
Files: `test/models/menu_performance_mv_test.rb`, `test/models/restaurant_analytics_mv_test.rb`, `test/models/dw_orders_mv_test.rb`
Root cause: Views exist in structure.sql but are never populated (REFRESH). Setup attempted `CREATE MATERIALIZED VIEW` inside a transaction (impossible for DDL). Fix: use `REFRESH MATERIALIZED VIEW` in setup instead.

**4. Real code bug — NameError typo in production code**
File: `app/services/size_mapping_cost_service.rb` line with `ze_cost[:overhead_cost]` (should be `size_cost`) and missing `packaging_cost` in total calculation.
Fix: Fixed the typo and added `packaging_cost` to the total. Unskipped the test and wrote a real assertion.

**5. CookieStore session.id instability**
File: `test/controllers/ordr_payments_controller_test.rb`
Root cause: Rails CookieStore computes `session.id` as a digest of session data, which changes on every request in the test env. Cannot pre-seed an `Ordrparticipant.sessionid` to match. Kept skipped with updated documentation.

**6. System test JS/session isolation**
Files: `test/system/smartmenu_order_state_test.rb`, `test/system/ocr_menu_imports_flow_test.rb`
Root cause: Tests use `add_item_to_order` helper that bypasses the Stimulus controller; modal UI state and participant session IDs cannot be injected. Kept skipped with updated documentation.

**Why:** Understanding these patterns prevents re-introducing bad skips and guides future fixture and test infrastructure decisions.
**How to apply:** When writing new tests that involve materialized views, session IDs, or conditional fixture data, apply the patterns learned above.
