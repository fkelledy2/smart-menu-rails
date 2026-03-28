## Bug Hunter Memory Index

## User
- [user_fergus.md](user_fergus.md) — Fergus: lead engineer on Smart Menu, works on all layers of the stack

## Patterns & Gotchas
- [pattern_double_audit_write.md](pattern_double_audit_write.md) — CRM reopen action writes duplicate audit records; LeadTransitionService already writes the stage_changed audit
- [pattern_enforce_scope_no_halt.md](pattern_enforce_scope_no_halt.md) — JwtAuthenticated#enforce_scope! renders 403 but does not halt; action body continues executing
- [pattern_jwt_double_logging.md](pattern_jwt_double_logging.md) — DashboardController includes JwtAuthenticated AND inherits BaseController, causing double usage_log writes on scope-denied requests
- [pattern_calendly_toctou.md](pattern_calendly_toctou.md) — CalendlyEventHandler idempotency check uses exists? + find_by (two queries), not safe under concurrent Sidekiq retries
- [pattern_rack_attack_hardcoded_limits.md](pattern_rack_attack_hardcoded_limits.md) — Rack::Attack JWT throttles hardcode limit: 60/1000 instead of reading per-token rate_limit_per_minute/hour from the DB record
- [pattern_api_v1_authenticate_user_conflict.md](pattern_api_v1_authenticate_user_conflict.md) — Orders/Menus/Restaurants V1 controllers add Devise authenticate_user! alongside JWT auth, blocking JWT-only write requests
- [pattern_api_v1_missing_authorize.md](pattern_api_v1_missing_authorize.md) — MenusController#index, MenuItemsController#index, VisionController#detect_menu_items missing authorize — 500 for non-super-admins
- [pattern_api_v1_orders_schema_mismatch.md](pattern_api_v1_orders_schema_mismatch.md) — Api::V1::OrdersController references subtotal/total/customer_name/calculate_totals! which don't exist on Ordr
- [pattern_usage_count_race_condition.md](pattern_usage_count_race_condition.md) — AdminJwtToken#record_usage! is non-atomic (usage_count+1 read-write race); log_api_usage_for_current_request is defined but never called
