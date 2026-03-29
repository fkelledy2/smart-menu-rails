---
name: EmployeesController#set_employee continues execution after redirect
description: set_employee calls redirect_to but does not return, so the action body runs against nil @employee — NoMethodError or tenant data leak
type: project
---

`app/controllers/employees_controller.rb` lines 341-343:
```ruby
if @employee.nil? || (@employee.restaurant.user != current_user)
  redirect_to root_url
end
```
The `redirect_to` is not followed by `return`. Rails does not halt execution on redirect in a before_action callback unless an explicit `return` is present. The calling action then tries to `authorize @employee` (nil) and crashes with NoMethodError.

**Why:** Missing `return` after `redirect_to`.

**How to apply:** Change to `redirect_to root_url and return`.
