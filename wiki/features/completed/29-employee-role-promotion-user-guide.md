# Employee Role Promotion — User Guide

**Feature #29 — Completed 2026-04-01**

---

## Overview

Restaurant admins and managers can now promote or demote staff members directly from the Staff Management section — no need to delete and re-invite an employee. Every role change is recorded in an immutable audit log and the affected employee receives an email notification instantly.

---

## Who Can Do What

| Acting Role | Can change to... | Cannot change... |
|-------------|------------------|------------------|
| **Admin**   | Any role (staff, manager, admin) for any other employee in their restaurant | Their own role |
| **Manager** | Staff → Manager only | Any other combination; their own role |
| **Staff**   | Nothing | — |

An employee can never change their own role.

---

## How to Change a Role

1. Navigate to your restaurant's **Staff** section (`/restaurants/:id/edit`, scroll to the Staff tab).
2. In the staff list, click the **Actions** dropdown (three-dot menu) next to the employee whose role you want to change.
3. If you have permission, you will see a **"Change Role"** option. Click it.
4. An inline form appears directly below that employee's row — no page reload.
5. Select the **New Role** from the dropdown (only roles you are permitted to set will appear).
6. Enter a **Reason** for the change (minimum 10 characters — this is stored in the audit log).
7. If you are demoting the employee, a yellow warning panel appears. Check the confirmation checkbox to confirm the demotion.
8. Click **Update Role**.
9. The employee's row updates in place (no page reload), showing the new role badge immediately.
10. The affected employee receives a branded email notification automatically.

### Closing the Form Without Saving

Click the **Cancel** button or the **X** in the form header to dismiss without making any changes.

---

## Viewing Role History

1. In the **Actions** dropdown next to any employee, click **"Role History"** (visible to managers and admins).
2. A history panel expands inline below the employee row showing all past role changes in reverse chronological order.
3. Each entry shows: date, previous role, new role, who made the change, and the reason provided.

---

## Email Notification

The promoted or demoted employee receives an email to the address registered on their account. The email includes:

- Their previous role and new role
- Context about what the new role allows (for promotions)
- The reason provided by the person who made the change
- The date and time the change took effect

---

## Audit Trail

All role changes are stored in the `employee_role_audits` table. This table is **append-only**: records cannot be updated or deleted via the application. Every audit record captures:

- `employee` — the employee whose role changed
- `restaurant` — the restaurant context
- `changed_by` — the employee who made the change
- `from_role` — the previous role
- `to_role` — the new role
- `reason` — the mandatory justification
- `created_at` — the exact timestamp (immutable)

---

## Feature Flag

The Change Role and Role History UI actions are gated behind the Flipper feature flag `employee_role_promotion`.

- **Default**: Disabled (flag exists but is off)
- **Enable globally**: `Flipper.enable(:employee_role_promotion)`
- **Enable per-restaurant**: `Flipper.enable(:employee_role_promotion, restaurant)` (not yet wired — currently actor-based)
- **Disable**: `Flipper.disable(:employee_role_promotion)`

When the flag is disabled, existing roles are completely unaffected — only the UI actions are hidden. Role changes made while the flag was enabled remain intact.

---

## Permissions Summary

The Pundit policy enforces:

- `EmployeePolicy#change_role?` — evaluated per request; no session invalidation required
- `EmployeePolicy#view_role_history?` — managers and admins only

Role changes propagate immediately: the next time the promoted employee makes a request, Pundit evaluates their new role.

---

## Technical Reference

| Component | Location |
|-----------|----------|
| Migration | `db/migrate/20260401172749_create_employee_role_audits.rb` |
| Model | `app/models/employee_role_audit.rb` |
| Service | `app/services/employees/role_change_service.rb` |
| Job | `app/jobs/employee_role_changed_job.rb` |
| Mailer | `app/mailers/employee_mailer.rb` |
| Policy | `app/policies/employee_policy.rb` (change_role?, view_role_history?) |
| Policy | `app/policies/employee_role_audit_policy.rb` |
| Controller actions | `EmployeesController#new_role_change`, `#change_role`, `#role_history` |
| Views | `app/views/employees/_change_role_form.html.erb`, `_role_history.html.erb` |
| Stimulus | `role_change_controller.js`, `role_change_form_controller.js` |
| Flipper flag | `employee_role_promotion` |
