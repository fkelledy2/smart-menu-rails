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
- [pattern_inline_payment_no_order_event.md](pattern_inline_payment_no_order_event.md) — create_inline_payment (Square) never emits paid OrderEvent or calls projector — order stuck in billrequested forever
- [pattern_stripe_account_updated_boolean_bug.md](pattern_stripe_account_updated_boolean_bug.md) — StripeIngestor handle_account_updated uses !obj[field].nil? on boolean fields — always true even when field is false
- [pattern_aasm_autopay_never_triggered.md](pattern_aasm_autopay_never_triggered.md) — AutoPayCaptureJob only enqueued from AASM requestbill callback; OrderEventProjector uses update_columns which bypasses AASM — auto-pay silently broken
- [pattern_ordritems_missing_covercharge.md](pattern_ordritems_missing_covercharge.md) — OrdritemsController#update_ordr omits covercharge from gross; also applies taxes to nett only (not nett+covercharge)
- [pattern_ocr_section_double_auth.md](pattern_ocr_section_double_auth.md) — OcrMenuSectionsController authorize passes for admin but owns_section? rejects — admin gets 403
- [pattern_download_link_raw_jwt_in_url.md](pattern_download_link_raw_jwt_in_url.md) — download_link is a GET route; raw JWT passed as hidden field ends up in URL query string and server access logs
- [pattern_send_lead_email_not_idempotent.md](pattern_send_lead_email_not_idempotent.md) — Crm::SendLeadEmailJob creates CrmEmailSend then deliver_later; retry after create! sends duplicate email
- [pattern_ordrparticipant_anonymous_update.md](pattern_ordrparticipant_anonymous_update.md) — OrdrparticipantsController#update skips verify_authorized and has no session ownership check — anonymous users can mutate any participant's name/allergens
- [pattern_intents_controller_untracked_payment.md](pattern_intents_controller_untracked_payment.md) — Payments::IntentsController creates Stripe PaymentIntent without PaymentAttempt record — financial tracking gap
- [pattern_stripe_connect_invalid_status.md](pattern_stripe_connect_invalid_status.md) — StripeConnectController#return uses :active (invalid enum) instead of :enabled — every Stripe Connect onboarding silently fails
- [pattern_checkout_qr_missing_payment_attempt.md](pattern_checkout_qr_missing_payment_attempt.md) — checkout_qr Stripe path creates no PaymentAttempt — webhook reconciliation fails, Ledger entity_id is nil
- [pattern_dw_orders_mv_scope_all_fallback.md](pattern_dw_orders_mv_scope_all_fallback.md) — DwOrdersMvPolicy falls back to scope.all when restaurant_id column absent — cross-tenant analytics data leak
- [pattern_demo_bookings_weak_admin_guard.md](pattern_demo_bookings_weak_admin_guard.md) — Admin::DemoBookingsController require_mellow_admin! missing admin? check — any @mellow.menu user can access DemoBookings
