---
name: JWT double usage logging on DashboardController
description: DashboardController includes JwtAuthenticated (adds after_action :log_api_usage) AND inherits BaseController which has log_api_usage_for_current_request — on scope-denied requests, log_api_usage is called twice (once explicitly in enforce_scope!, once by after_action)
type: feedback
---

`Api::V1::Analytics::DashboardController` includes `JwtAuthenticated`, which registers `after_action :log_api_usage`. `JwtAuthenticated#enforce_scope!` also calls `log_api_usage(override_status: 403)` explicitly before rendering the 403. This means a scope-denied request logs a usage record twice: once inline at status 403, and once from the `after_action` at the final response status.

**Why:** The concern was designed for standalone controllers that don't inherit BaseController's JWT handling. DashboardController does both — it inherits BaseController (which has its own `log_api_usage_for_current_request`) and includes the concern.

**How to apply:** DashboardController should NOT include `JwtAuthenticated` as a separate concern. Authentication and usage logging for JWT-authenticated API controllers should flow entirely through `BaseController#authenticate_api_user!` and `BaseController#log_api_usage_for_current_request`. The `JwtAuthenticated` concern was intended for controllers outside the `Api::V1` hierarchy.
