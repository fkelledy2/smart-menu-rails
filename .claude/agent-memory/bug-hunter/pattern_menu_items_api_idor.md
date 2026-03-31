---
name: API MenuItems IDOR
description: Api::V1::MenuItemsController#index IDOR — unscoped Menu.find, no Pundit auth; any JWT token could enumerate any restaurant's menu items
type: feedback
---

Api::V1::MenuItemsController#index had `skip_after_action :verify_authorized` and `Menu.find(params[:menu_id])` with no tenant scoping. Any authenticated JWT token could supply a menu_id from a different restaurant and retrieve its items.

**Fix applied:**
- Removed `skip_after_action :verify_authorized`
- Added `authorize @menu, :show?` in `index`
- Scoped `set_menu` to `Menu.where(restaurant_id: current_user.restaurants.select(:id)).find(...)` so cross-tenant lookup returns 404

**Why:** MenuPolicy#show? returns `true` for all authenticated users, so the authorize call allows public menus through while still triggering `verify_authorized`. The tenant scoping is the real guard — menu not in user's accessible restaurants → 404.

**How to apply:** When reviewing API controllers that load resources by ID, always check both (1) tenant scope in the finder and (2) Pundit authorize call.
