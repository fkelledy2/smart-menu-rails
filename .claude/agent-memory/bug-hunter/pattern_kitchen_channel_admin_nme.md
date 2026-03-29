---
name: KitchenChannel admin? NoMethodError
description: KitchenChannel#handle_status_update called current_user.admin? which doesn't exist on User; should be super_admin?
type: feedback
---

`KitchenChannel#handle_status_update` at `app/channels/kitchen_channel.rb:49` called `current_user.admin?`, but `User` only defines `super_admin?` (line 110 of `app/models/user.rb`). Every staff WebSocket status update triggered a `NoMethodError`.

Fixed: changed to `current_user.super_admin?`.

**Why:** Recurring pattern — `admin?` does not exist on User anywhere in the codebase; `super_admin?` is the correct method. Same root cause as BarDashboardController and ApplicationController#ensure_admin! bugs.

**How to apply:** Any new code testing for super-admin status via ActionCable must use `current_user.super_admin?`, not `current_user.admin?`.
