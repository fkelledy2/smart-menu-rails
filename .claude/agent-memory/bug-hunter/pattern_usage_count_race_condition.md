---
name: AdminJwtToken usage_count increment is non-atomic
description: record_usage! reads usage_count from the AR object and increments it, losing concurrent counts under parallel requests
type: project
---

`app/models/admin_jwt_token.rb` `record_usage!` uses:
```ruby
update_columns(
  last_used_at: Time.current,
  usage_count: usage_count + 1,
)
```

This reads `usage_count` from the in-memory AR object then writes `usage_count + 1`. Under concurrent requests on the same token, two threads can read the same stale value and both write the same incremented value, losing one count.

Also: `log_api_usage_for_current_request` is defined in `Api::V1::BaseController` (line 76) but is never registered as an `after_action` and never called. JWT usage logs are NEVER written for V1 API requests that go through the base controller path. Only `JwtAuthenticated` concern (used by the non-V1 DashboardController) writes usage logs.

**Why:** The fix for the double-logging bug (removing JwtAuthenticated from DashboardController) should have also wired up `log_api_usage_for_current_request` as an after_action in the V1 BaseController.

**How to apply:** Replace `usage_count: usage_count + 1` with a SQL increment: `update_columns(last_used_at: Time.current)` + a separate `increment_counter(:usage_count, id)` or raw SQL `SET usage_count = usage_count + 1`. Register `log_api_usage_for_current_request` as an `after_action` in V1 BaseController.
