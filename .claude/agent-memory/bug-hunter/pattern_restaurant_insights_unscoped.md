---
name: RestaurantInsightsController#set_restaurant uses unscoped Restaurant.find — IDOR on insights data
description: RestaurantInsightsController uses Restaurant.find instead of current_user.restaurants.find — any authenticated user can query any restaurant's top performers, slow movers, prep times, voice triggers, and abandonment funnel
type: project
---

In app/controllers/restaurant_insights_controller.rb line 81:
```ruby
def set_restaurant
  @restaurant = Restaurant.find(params[:id])
end
```

All data endpoints (top_performers, slow_movers, prep_time_bottlenecks, voice_triggers, abandonment_funnel) are gated only by authorize @restaurant, :show? — but Pundit policy for Restaurant show? typically allows the record's owner, so an attacker can read another restaurant's operational data by supplying the correct id.

Fix: scope to current_user.restaurants.find(params[:id]).

**Why:** Same multi-tenant isolation issue as IngredientsController.
**How to apply:** Always scope restaurant lookups to current_user.
