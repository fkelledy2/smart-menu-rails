---
name: ordrs_controller show admin? NoMethodError
description: OrdrsController#show calls current_user.admin? which doesn't exist on User — NoMethodError on every authenticated order view
type: feedback
---

`OrdrsController#show` at line 118 builds an analytics properties hash with `current_user.admin? ? 'staff_view' : 'customer_view'`. `User` only defines `super_admin?`, not `admin?`. This hash is constructed before `AnalyticsService.track_user_event` is called, so the rescue inside the service does not protect against it.

**Why:** The `return unless current_user` guard at line 111 means this crashes for every logged-in user, not just admins. The NoMethodError propagates up to the controller action unhandled.

**How to apply:** Replace `current_user.admin?` with `current_user.super_admin?` at `app/controllers/ordrs_controller.rb:118`. Recurring pattern — this exact mistake has been seen in BarDashboardController and KitchenChannel (already fixed).
