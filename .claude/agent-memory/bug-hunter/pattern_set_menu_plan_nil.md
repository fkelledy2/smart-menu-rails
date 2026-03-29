---
name: Menus::BaseController#set_menu crashes when user has no plan
description: set_menu calls current_user.plan.itemspermenu without guarding plan nil — NoMethodError for users without a plan record
type: project
---

`app/controllers/menus/base_controller.rb` line 102:
```ruby
@canAddMenuItem = @menuItemCount < current_user.plan.itemspermenu || current_user.plan.itemspermenu == -1
```
`current_user.plan` can be nil for new users who have not been assigned a plan. Calling `.itemspermenu` on nil raises NoMethodError, which surfaces on every menu edit page for that user.

**Why:** No nil guard on `current_user.plan` before method call.

**How to apply:** Guard with `current_user.plan&.itemspermenu` and default to a safe value, e.g. `plan = current_user.plan; @canAddMenuItem = plan.nil? || plan.itemspermenu == -1 || @menuItemCount < plan.itemspermenu`.
