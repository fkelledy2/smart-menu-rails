---
name: pattern_bar_dashboard_admin_undefined
description: BarDashboardController called current_user.admin? which doesn't exist on User; should be super_admin? — NoMethodError on bar dashboard access
type: feedback
---

`BarDashboardController#set_restaurant` called `current_user&.admin?`. `User` does not define `admin?` — it only has `super_admin?`. This causes `NoMethodError` when any non-owner tries to access the bar dashboard, even if they should be allowed.

**Why:** The `admin?` method is a common Devise pattern for admin checks, but this app uses `super_admin?` (backed by a `super_admin` boolean column) rather than a role/admin column.

**Fix:** Changed `current_user&.admin?` to `current_user&.super_admin?`.

**How to apply:** Whenever scanning controllers for admin guards, always verify that the method called (`admin?`, `is_admin?`, etc.) actually exists on `User`. The only platform-wide admin check is `super_admin?`.
