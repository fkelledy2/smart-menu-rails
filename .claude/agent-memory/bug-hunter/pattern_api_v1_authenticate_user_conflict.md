---
name: API V1 authenticate_user! conflict with JWT auth
description: OrdersController, MenusController, RestaurantsController add Devise before_action :authenticate_user! which redirects JWT-only callers to sign-in on write actions
type: project
---

`app/controllers/api/v1/orders_controller.rb`, `menus_controller.rb`, and `restaurants_controller.rb` all declare `before_action :authenticate_user!` in addition to inheriting `authenticate_api_user!` from `Api::V1::BaseController`. For JWT token holders without a Devise session, mutating endpoints (create/update/destroy) will redirect to `/users/sign_in` instead of processing the request.

**Why:** These controllers were likely written for session-based auth before JWT support was added, and the `authenticate_user!` calls were never removed.

**How to apply:** When investigating JWT API auth failures on write operations, check for dual `authenticate_user!` / `authenticate_api_user!` guards. The fix is to remove `before_action :authenticate_user!` from V1 API controllers — `authenticate_api_user!` in the base controller covers both JWT and session paths.
