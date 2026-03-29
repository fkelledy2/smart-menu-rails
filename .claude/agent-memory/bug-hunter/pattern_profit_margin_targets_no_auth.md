---
name: profit_margin_targets_no_auth
description: ProfitMarginTargetsController and MenuitemCostsController have no Pundit authorization and unscoped Restaurant.find — any authenticated user can read/write any restaurant's cost data
type: project
---

ProfitMarginTargetsController (`app/controllers/profit_margin_targets_controller.rb`) and MenuitemCostsController (`app/controllers/menuitem_costs_controller.rb`) both:
1. Use `Restaurant.find(params[:restaurant_id])` in `set_restaurant` without scoping to `current_user`
2. Have zero `authorize` calls or `verify_authorized` after_actions

Any authenticated user can create/update/destroy profit margin targets and menuitem costs for any restaurant.

**Why:** No Pundit wiring was added when these controllers were created.
**How to apply:** Flag as P1 IDOR. Fix by adding `verify_authorized` after_actions and `authorize @target` / `authorize @menuitem_cost` calls in each action, plus scope `set_restaurant` to `current_user.restaurants.find(...)`.
