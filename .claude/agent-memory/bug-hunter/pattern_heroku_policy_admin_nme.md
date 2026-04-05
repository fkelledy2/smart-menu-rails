---
name: HerokuAppInventorySnapshotPolicy admin? NoMethodError
description: HerokuAppInventorySnapshotPolicy called user.admin? (NoMethodError) — correct is user.super_admin? (FIXED)
type: project
---

`HerokuAppInventorySnapshotPolicy::Scope#resolve` and `#super_admin?` both called `user.admin?` which doesn't exist on `User` (correct method is `super_admin?`). Fixed by replacing both occurrences.

**Why:** Same class of bug as the recurring `admin?` vs `super_admin?` pattern — any code calling `user.admin?` will raise NoMethodError. The policy was new and introduced the bug by following a wrong pattern.

**How to apply:** Always use `user.super_admin?` for admin checks in Pundit policies. `user.admin?` does not exist on User.
