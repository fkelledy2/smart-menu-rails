# Employee Role Promotion

## Status
- Priority Rank: #28
- Category: Post-Launch
- Effort: S
- Dependencies: Existing `Employee` model (role enum already present), `StaffInvitation` model (already exists), Pundit `EmployeePolicy`

## Problem Statement
Restaurant managers currently cannot promote an existing staff member to a higher role without deleting and re-inviting them. The `Employee` model already holds a `role` enum (`staff: 0, manager: 1, admin: 2`), but there is no UI or audit trail for changing that role on an existing employee record. Restaurants with growing teams need a safe, audited mechanism to elevate trusted staff members without disrupting their account history or order records.

## Success Criteria
- A restaurant admin or manager can change the role of any employee in their restaurant from the staff management UI
- Every role change is recorded in an immutable audit log
- The employee being promoted receives an email notification of their new role
- A restaurant admin cannot promote beyond `admin` (their own level)
- A manager can promote `staff` to `manager` only; only an `admin` can promote to `admin`
- Role changes are reflected immediately — the employee's Pundit permissions update on their next request

## User Stories
- As a restaurant admin, I want to promote a trusted manager to admin so they can manage billing and restaurant settings while I'm away.
- As a restaurant manager, I want to promote a capable staff member to manager so they can handle order edits and menu updates during busy periods.
- As a restaurant admin, I want to see the full role history for any employee so I have an accountability trail.
- As a promoted employee, I want to receive an email confirming my new role and what additional access it grants.

## Functional Requirements
1. The staff list UI (existing `/restaurants/:id/employees` or equivalent) gains a "Change Role" action for each employee visible to users with sufficient permission.
2. Clicking "Change Role" opens a Turbo Modal (no new JS framework) with the current role displayed and a select input for the target role.
3. A mandatory reason field (min 10 characters) must be completed before the change can be submitted.
4. The system validates that the acting user has permission to make the change (see Pundit policy below).
5. On submission, the `Employee#role` is updated in a transaction that also creates an `EmployeeRoleAudit` record.
6. An email notification is sent to the promoted/demoted employee via `EmployeeMailer#role_changed`.
7. The employee's active sessions are not invalidated (role is checked per-request via Pundit, so access changes are immediate).
8. The staff list shows each employee's current role and a "Role history" link that opens a Turbo Frame panel listing all `EmployeeRoleAudit` records for that employee.
9. An employee cannot change their own role.
10. Demotion follows the same flow as promotion — an admin can demote any role; a manager can demote `manager` to `staff`.

## Non-Functional Requirements
- The `EmployeeRoleAudit` table must be append-only: no update or delete actions are permitted via the application (enforce at the Pundit policy level).
- All role change actions are logged in the existing audit infrastructure.
- The UI must use Hotwire Turbo Frames/Streams — no React or other JS framework.
- Performance: changing a role must not trigger a full page reload; use Turbo Streams to update the employee row in place.

## Technical Notes

### Architecture note — roles live on Employee, NOT User
The raw spec proposed adding `role_level` to the `User` model. This is incorrect for the Smart Menu architecture. Roles are scoped per restaurant via the `Employee` model (`employee.role`). A `User` can be a `staff` at restaurant A and an `admin` at restaurant B simultaneously. Do not add role columns to `User`.

### New model: EmployeeRoleAudit
```ruby
create_table :employee_role_audits do |t|
  t.references :employee,    null: false, foreign_key: true
  t.references :restaurant,  null: false, foreign_key: true
  t.references :changed_by,  null: false, foreign_key: { to_table: :employees }
  t.integer    :from_role,   null: false  # uses Employee role enum values
  t.integer    :to_role,     null: false
  t.text       :reason,      null: false
  t.datetime   :created_at,  null: false
  # No updated_at — this record is immutable once created
end
add_index :employee_role_audits, :employee_id
add_index :employee_role_audits, :restaurant_id
add_index :employee_role_audits, :created_at
```

### Service to create
`app/services/employees/role_change_service.rb`:
- Accepts: acting_employee, target_employee, to_role, reason
- Validates authority (raise `Pundit::NotAuthorizedError` if not permitted)
- Wraps `Employee#update!(role:)` and `EmployeeRoleAudit#create!` in a transaction
- Enqueues `EmployeeRoleChangedJob` for email delivery (do not call mailer inline)

### Pundit policy
Extend `app/policies/employee_policy.rb`:
```ruby
def change_role?
  # Admins can change any role (up or down) for employees in their restaurant
  # Managers can only promote staff → manager (not to admin, not demote)
  acting_employee = current_employee_for_restaurant(record.restaurant_id)
  return false unless acting_employee
  return false if acting_employee.id == record.id  # cannot change own role

  acting_employee.admin? || (acting_employee.manager? && record.staff?)
end

def view_role_history?
  acting_employee = current_employee_for_restaurant(record.restaurant_id)
  acting_employee&.manager? || acting_employee&.admin?
end
```

### Mailer
`app/mailers/employee_mailer.rb` — `role_changed(employee_role_audit)`:
- Uses the existing branded email layout (#2 must be complete)
- States: old role, new role, changed by (name), reason, effective date

### Flipper flag
- `employee_role_promotion` — gates the "Change Role" UI; safe to roll out to a subset of restaurants

### No RolePermission model needed
Permissions are enforced by Pundit policies already. A separate `RolePermission` database table would duplicate what Pundit already manages declaratively.

### No "approval workflow" in v1
The raw spec proposed a request/approval workflow. This is out of scope for v1 — direct promotion (with the acting user having sufficient Pundit authority) is the correct first iteration. Approval workflows can be added in a later iteration if multi-location restaurant groups require it.

## Acceptance Criteria
1. An admin employee can change a staff employee's role to `manager` or `admin`; the change appears immediately in the staff list.
2. A manager employee can change a staff employee's role to `manager`; the manager cannot set a role of `admin`.
3. A manager employee cannot change another manager's role.
4. An employee cannot change their own role.
5. Every role change creates exactly one `EmployeeRoleAudit` record with the correct `from_role`, `to_role`, `changed_by`, and `reason`.
6. After a role promotion, the promoted employee's Pundit permissions reflect the new role on their next request (no session invalidation required).
7. The promoted employee receives an email notification via the branded mailer layout.
8. The role history panel for an employee lists all audit records in reverse chronological order.
9. Attempting to delete or update an `EmployeeRoleAudit` record via the application raises `Pundit::NotAuthorizedError`.
10. The `employee_role_promotion` Flipper flag, when disabled, hides the "Change Role" action entirely — existing roles are unaffected.

## Out of Scope
- Employee self-service role requests (employee asks for promotion; manager approves)
- Bulk role changes across multiple employees in one operation
- Role changes for employees who belong to a different restaurant than the acting user's current restaurant context
- Minimum time-in-role requirements before promotion eligibility

## Open Questions
1. Should demotion (e.g. admin → staff) require a two-step confirmation given the severity? Recommend yes — a confirmation modal for demotions.
2. Does the existing `EmployeePolicy` already handle the `manager?` / `admin?` helper, or does it rely on a `current_employee` context passed from the controller? Confirm before writing service.
3. Should the `changed_by` reference use the `Employee` record or the `User` record? Recommend `Employee` to keep everything restaurant-scoped.
