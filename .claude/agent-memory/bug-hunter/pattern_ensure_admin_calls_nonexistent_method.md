---
name: ensure_admin! calls non-existent admin? method
description: ApplicationController#ensure_admin! called current_user.admin? which does not exist on User — every controller using this guard silently denied all users
type: feedback
---

`User` has `super_admin?` (delegates to the `super_admin` boolean column) but no `admin?` method. `ApplicationController#ensure_admin!` called `current_user&.admin?` which always returns `nil` (method missing would raise but `&.` returns nil), causing every guarded action to redirect to root.

**Why:** `admin?` was likely copied from an older codebase convention. `User` only exposes `super_admin?`.

**How to apply:** Any guard that needs to restrict to internal staff should use `current_user&.super_admin?`. The fix was applied in ApplicationController.
