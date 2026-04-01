---
name: Employee Role Promotion v1
description: Employee Role Promotion #29: EmployeeRoleAudit model, RoleChangeService, Flipper flag, Pundit policy pattern, asset manifest gotcha, t.references index duplication gotcha (April 2026)
type: project
---

Feature #29 — Employee Role Promotion — COMPLETED 2026-04-01

## Key Architectural Decisions

1. **Roles live on `Employee`, not `User`**: A user can be staff at restaurant A and admin at restaurant B simultaneously. Never add role columns to `User`.

2. **Pundit policy pattern**: `EmployeePolicy#change_role?` uses `user.employees.find_by(restaurant_id: record.restaurant_id)` to look up the acting employee scoped to the target employee's restaurant. The global `@current_employee` set in `ApplicationController` is not restaurant-scoped.

3. **Immutability via before_update/before_destroy hooks**: `EmployeeRoleAudit` raises `ActiveRecord::ReadOnlyRecord` on both hooks. No `updated_at` column — only `created_at`.

4. **Service validates then wraps in a transaction**: `Employees::RoleChangeService` runs all validation first, then wraps `Employee#update!` and `EmployeeRoleAudit#create!` in a single `Employee.transaction` block.

5. **Email delivered via Sidekiq job**: `EmployeeRoleChangedJob.perform_later(audit.id)` is enqueued after the transaction commits. Never call mailer inline in the service.

## Gotchas Encountered

- **t.references adds index automatically**: Using `t.references` in a migration already creates indexes. Adding explicit `add_index` calls afterward causes `PG::DuplicateTable`. Only add the `created_at` index manually since `t.references` doesn't create it.

- **Asset manifest requirement**: New Stimulus controllers must be added to both `app/assets/config/manifest.js` AND `app/javascript/controllers/index.js`. Missing manifest entry causes `ActionView::Template::Error: Asset was not declared to be precompiled` in controller tests.

- **ActiveJob::TestHelper not included in ActiveSupport::TestCase**: Must explicitly `include ActiveJob::TestHelper` to use `assert_enqueued_with` in service tests.

- **ActionMailer::TestHelper not included in ActiveJob::TestCase**: Must explicitly `include ActionMailer::TestHelper` in job tests to use `assert_emails`.

## Files Created

- `db/migrate/20260401172749_create_employee_role_audits.rb`
- `app/models/employee_role_audit.rb`
- `app/services/employees/role_change_service.rb`
- `app/jobs/employee_role_changed_job.rb`
- `app/mailers/employee_mailer.rb`
- `app/policies/employee_role_audit_policy.rb`
- `app/views/employee_mailer/role_changed.html.erb`
- `app/views/employee_mailer/role_changed.text.erb`
- `app/views/employees/_change_role_form.html.erb`
- `app/views/employees/_role_history.html.erb`
- `app/views/employees/_employee_row.html.erb`
- `app/views/employees/role_history.turbo_stream.erb`
- `app/javascript/controllers/role_change_controller.js`
- `app/javascript/controllers/role_change_form_controller.js`
- `test/models/employee_role_audit_test.rb`
- `test/services/employees/role_change_service_test.rb`
- `test/jobs/employee_role_changed_job_test.rb`
- `test/mailers/employee_mailer_test.rb`
- `test/fixtures/employee_role_audits.yml`

## Files Modified

- `app/models/employee.rb` — added `has_many :employee_role_audits` and `has_many :role_changes_made`
- `app/policies/employee_policy.rb` — added `change_role?` and `view_role_history?`
- `app/controllers/employees_controller.rb` — added `new_role_change`, `change_role`, `role_history` actions
- `app/views/restaurants/sections/_staff_2025.html.erb` — added Turbo Frame placeholders and Change Role/Role History actions
- `config/routes.rb` — added `new_role_change`, `change_role`, `role_history` member routes
- `config/initializers/flipper.rb` — registered `employee_role_promotion` flag (disabled by default)
- `app/assets/config/manifest.js` — linked new Stimulus controllers
- `app/javascript/controllers/index.js` — imported and registered new controllers
- `test/fixtures/employees.yml` — added `staff_member` and `admin_employee` fixtures
- `test/policies/employee_policy_test.rb` — added `change_role?` and `view_role_history?` tests

## Flipper Flag

`employee_role_promotion` — disabled by default. Enable via Flipper UI or `Flipper.enable(:employee_role_promotion)`.

**Why:** Incremental rollout; hides "Change Role" and "Role History" UI entirely when disabled. Existing roles unaffected.
