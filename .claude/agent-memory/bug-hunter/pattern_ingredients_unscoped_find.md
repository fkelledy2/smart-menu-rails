---
name: IngredientsController#set_restaurant uses Restaurant.find (unscoped) — IDOR on ingredient edit/destroy
description: IngredientsController#set_restaurant calls Restaurant.find instead of current_user.restaurants.find — any authenticated user can access/mutate any restaurant's ingredients by crafting the URL
type: project
---

In app/controllers/ingredients_controller.rb line 78:
```ruby
def set_restaurant
  @restaurant = Restaurant.find(params[:restaurant_id])
end
```

There is no ownership check. Any authenticated user can supply any restaurant_id and reach show/edit/update/destroy actions on that restaurant's ingredients.

Fix: scope to current_user.restaurants.find(params[:restaurant_id]) and add rescue ActiveRecord::RecordNotFound → 404.

**Why:** Multi-tenant isolation requires all restaurant lookups to be scoped to the current user's accessible restaurants.
**How to apply:** All set_restaurant callbacks must use current_user.restaurants.find or equivalent scoped query.
