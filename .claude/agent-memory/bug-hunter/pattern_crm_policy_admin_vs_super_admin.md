---
name: CrmEmailSendPolicy and CrmLeadNotePolicy instance mellow_admin? uses admin? not super_admin?
description: Instance-level mellow_admin? in CrmEmailSendPolicy/CrmLeadNotePolicy used admin? (not super_admin?) — allowed any @mellow.menu user with admin=true to pass Pundit even without super_admin=true (FIXED)
type: project
---

`CrmEmailSendPolicy` and `CrmLeadNotePolicy` had a split definition of `mellow_admin?`:

- The `Scope` inner class correctly used `user.super_admin?`
- The instance-level `mellow_admin?` used `user.admin?` — the plain `admin` boolean column, not `super_admin`

Any `@mellow.menu` user with `admin=true` (but `super_admin=false`) could pass `create?` / `destroy?` Pundit checks for CRM emails and notes.

**Why:** Likely a copy-paste error when the policies were written — the Scope and instance methods diverged.

**How to apply:** When reviewing CRM policies or adding new mellow-admin-only policies, always check that both the `Scope` inner class and the instance-level `mellow_admin?` use the same predicate (`super_admin?`). The `admin` boolean column grants admin-level access to a restaurant but NOT full super-admin privileges.
