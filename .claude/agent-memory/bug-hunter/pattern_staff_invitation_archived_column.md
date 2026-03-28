---
name: StaffInvitationsController archived column mismatch
description: employees.exists?(archived: false) queries a non-existent column; archival state is the status enum, not a boolean
type: project
---

`app/controllers/staff_invitations_controller.rb` line 32 calls `@restaurant.employees.exists?(user: existing_user, archived: false)`.

`Employee` has no `archived` boolean column. Archival state is tracked via the `status` integer enum: `{ inactive: 0, active: 1, archived: 2 }`. The correct guard would query against the `status` enum values.

In PostgreSQL this raises `ActiveRecord::StatementInvalid` or silently returns false, causing the duplicate-invitation guard to never trigger.

**Why:** Developer used a boolean mental model for archival instead of checking the actual enum-based schema.

**How to apply:** When investigating Employee queries, always check the `status` enum — there is no `archived` boolean on this model. Watch for the same pattern in other controllers that filter employees.
