---
name: Employee archived column — boolean column EXISTS (corrected)
description: Employee has BOTH a boolean archived column AND an archived enum in status — earlier note was wrong about the column not existing
type: project
---

CORRECTION: An earlier investigation incorrectly stated that `Employee` has no `archived` boolean column. The `db/schema.rb` confirms `t.boolean "archived", default: false` exists on the `employees` table.

`Employee` has:
- A `status` integer enum: `{ inactive: 0, active: 1, archived: 2 }`
- A separate `t.boolean "archived", default: false` column (used in two partial indexes)

So `employees.exists?(user: existing_user, status: :active, archived: false)` in `app/controllers/staff_invitations_controller.rb` line 32 is **valid** SQL. No bug here.

**Why:** The partial index `WHERE (archived = false)` in the schema made it look like a virtual condition, but the column is real.

**How to apply:** When investigating Employee queries, Employee has BOTH a status enum AND an archived boolean. Both are valid filter columns. Do not treat `archived: false` as a mistake on Employee.
