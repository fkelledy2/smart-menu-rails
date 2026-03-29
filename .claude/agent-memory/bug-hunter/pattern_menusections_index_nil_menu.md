---
name: MenusectionsController#index nil dereference when menu not found
description: index uses Menu.find_by but then calls @menu.menusections without checking nil — NoMethodError on invalid menu_id for JSON requests
type: project
---

`app/controllers/menusections_controller.rb` lines 13-22:
```ruby
@menu = Menu.find_by(id: params[:menu_id])
@menusections = if request.format.json?
  @menu.menusections.order(:sequence)   # <- crashes if @menu is nil
```
JSON requests hit the `@menu.menusections` path before the nil check that the HTML path gets via policy_scope. If `menu_id` does not exist or belongs to another tenant, this raises NoMethodError.

**Why:** find_by + nil guard missing for the JSON branch.

**How to apply:** Add `return head :not_found unless @menu` after the find_by.
