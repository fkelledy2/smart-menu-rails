---
name: RestaurantRemovalRequestsController anonymous unpublish DoS
description: Anonymous users could POST to create a removal request and immediately set preview_enabled:false on any restaurant (FIXED)
type: project
---

`RestaurantRemovalRequestsController#create` set `@restaurant.update!(preview_enabled: false)` whenever a removal request saved successfully. The controller has no authentication requirement — any anonymous user could POST `restaurant_id=X` and immediately take any restaurant's preview offline.

**Why:** The original intent was that creating a removal request should unpublish the preview, but no ownership check gated the unpublish. The fix adds `user_signed_in? && current_user.restaurants.exists?(id: @restaurant.id)` before the update call.

**How to apply:** Any action that mutates a restaurant's public visibility must verify the caller owns the restaurant, not just that they submitted a valid form. Anonymous form submissions should be queued for admin review only, never trigger immediate state changes.
