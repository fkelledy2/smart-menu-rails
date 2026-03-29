---
name: MenusController#index nil restaurant dereference
description: Public (unauthenticated) menus index uses find_by for restaurant then immediately calls @restaurant.id/.tablesettings without nil guard
type: project
---

MenusController#index lines 43-49: unauthenticated branch calls `Restaurant.find_by(id: params[:restaurant_id])` then immediately dereferences `@restaurant.id` and `@restaurant.tablesettings` without checking for nil. If the restaurant_id does not exist the request raises NoMethodError.

**Why:** find_by returns nil for unknown IDs; no guard before the chained calls.

**How to apply:** Add a nil guard (`return render :not_found unless @restaurant`) after the find_by call, before any attribute access.
