---
name: Admin::DemoBookingsController weak require_mellow_admin! guard
description: DemoBookingsController#require_mellow_admin! checks email suffix only, not admin? flag — inconsistent with all other admin controllers
type: project
---

`Admin::DemoBookingsController#require_mellow_admin!` (app/controllers/admin/demo_bookings_controller.rb) only checks `current_user&.email.to_s.end_with?('@mellow.menu')`. Every other admin controller checks both `current_user&.admin? && current_user&.email.to_s.end_with?('@mellow.menu')`.

A non-admin `@mellow.menu` user (e.g., a restaurant owner with that email domain) can access and modify DemoBooking records.

Fix: add `current_user&.admin? &&` to the condition. Long-term: extract `require_mellow_admin!` into `Admin::BaseController` to prevent per-controller drift.

**Why:** The guard was written without the `admin?` check, inconsistent with the pattern in sibling controllers.

**How to apply:** When reviewing admin controller access control, always verify both the `admin?` flag and email suffix are checked. Consider extracting to a shared base controller method.
