---
name: EmployeesController create/update nil dereference on employee.user
description: EmployeesController#create and #update call @employee.user.email after save but Employee#user is an optional belongs_to — nil if no user_id was set
type: project
---

`app/controllers/employees_controller.rb` lines 173 and 207:
```ruby
@employee.email = @employee.user.email
```
Employee records can exist without a linked User (e.g. manual/CSV creation without user_id). Calling `.email` on nil raises NoMethodError immediately after a successful save, causing a 500 when the employee was created/updated correctly.

**Why:** `belongs_to :user` can be nil; no safe navigation used.

**How to apply:** `@employee.email = @employee.user&.email` — or better, set email from params directly and not from the association.
