---
name: Admin controllers locked out — admin? does not exist on User
description: Multiple admin controllers call current_user&.admin? which always returns nil — both ensure_admin! and require_super_admin! redirect everyone including actual super admins
type: project
---

User model only defines super_admin? (line 110). There is no admin? method.

All controllers that call current_user&.admin? for an access gate return nil (falsy via safe navigation), causing:
- ensure_admin! to redirect ALL users, locking out super admins from admin area
- require_super_admin! (which requires admin? AND super_admin?) to also redirect super admins

Affected controllers (ensure_admin!/require_super_admin! using admin?):
- app/controllers/admin/restaurant_removal_requests_controller.rb:48,54
- app/controllers/admin/restaurant_claim_requests_controller.rb:48,54
- app/controllers/admin/city_crawls_controller.rb:38,44
- app/controllers/admin/menu_source_change_reviews_controller.rb:45,51
- app/controllers/admin/crawl_source_rules_controller.rb:67,71
- app/controllers/admin/discovered_restaurants_controller.rb:533,539
- app/controllers/admin/cache_controller.rb:121
- app/controllers/admin/jwt_tokens_controller.rb:137 (require_mellow_admin!)
- app/controllers/admin/crm/leads_controller.rb:162 (require_mellow_admin!)
- app/controllers/admin/crm/email_sends_controller.rb:49
- app/controllers/admin/crm/audits_controller.rb:30
- app/controllers/admin/crm/notes_controller.rb:72
- app/controllers/admin/demo_bookings_controller.rb:49

Side effects where admin? is only used for a non-gate path (less critical):
- app/controllers/application_controller.rb:325 — onboarding skip (reduces to super_admin? check, which is correct)
- app/controllers/ordr_station_tickets_controller.rb:51 — is_admin always nil but fallback paths still work
- app/controllers/kitchen_dashboard_controller.rb:31 — same as above

Fix: replace admin? with super_admin? throughout, or add def admin? = super_admin? alias to User model.

**Why:** User model only has super_admin boolean column; admin? was never defined.
**How to apply:** Any new admin gate must use super_admin? or email-domain checks only.
