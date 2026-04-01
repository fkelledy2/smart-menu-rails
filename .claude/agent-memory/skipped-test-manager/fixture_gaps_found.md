---
name: Fixture gaps discovered in skipped test audit (April 2026)
description: Missing fixture data that caused test skips — fixed by adding fixtures or correcting references
type: project
---

## Gaps Fixed

### 1. Employee fixture for users(:two) at restaurants(:one)
**File:** `test/policies/customer_wait_queue_policy_test.rb`
**Problem:** Test used `@employee = users(:two)` expecting an active employee record at restaurant :one. `users(:two)` has NO employee record — it belongs to a different restaurant. The active employee for restaurant :one is `users(:employee_staff)`.
**Fix:** Changed `@employee = users(:two)` to `@employee = users(:employee_staff)`.

### 2. Tablesetting for restaurants(:two)
**File:** `test/services/wait_time/estimation_service_test.rb`
**Problem:** Test for "all tables occupied, no historical data" path needed `restaurants(:two)` to have a tablesetting with capacity >= 2. It had none.
**Fix:** Added `restaurant_two_table` fixture in `test/fixtures/tablesettings.yml`.

## Fixture Structure Notes
- `employees.yml` has: `one` (manager, user: one, restaurant: one), `staff_member` (user: employee_staff, restaurant: one), `admin_employee` (user: admin, restaurant: one)
- `users(:two)` is a plain user with no employee record — used only for owner/non-employee tests
- `tablesettings.yml` originally only had fixtures for `restaurant: one`

**Why:** These gaps had existed for a while as the tests were simply skipped rather than fixed.
**How to apply:** When writing new tests that need employee or tablesetting data, prefer `users(:employee_staff)` or `tablesettings(:one)` for restaurant :one context.
