---
name: Partner API JWT missing restaurant_id enforcement
description: BaseController calls TokenValidator without restaurant_id — a token minted for Restaurant A can access Restaurant B's partner endpoints
type: feedback
---

`Api::V1::BaseController#authenticate_api_user!` calls `Jwt::TokenValidator.call(raw_jwt: raw_token)` without passing `restaurant_id:`. The validator only performs the restaurant_id mismatch check when `@restaurant_id` is present. Result: the restaurant-scope check is never triggered.

The `PartnerIntegrationPolicy#api_jwt_owner?` only checks `user.super_admin?` for JWT-authenticated requests, so any admin JWT (for any restaurant) passes authorization on any restaurant's CRM/workforce endpoint — cross-tenant data leak.

**Why:** The `restaurant_id:` argument to `TokenValidator.call` is optional and documentation says it should be provided. The base controller should pass `params[:restaurant_id]` when present.

**How to apply:** In `app/controllers/api/v1/base_controller.rb`, change the `TokenValidator.call` invocation to pass `restaurant_id: params[:restaurant_id]`. Also update `PartnerIntegrationPolicy#api_jwt_owner?` to check that `@current_api_restaurant&.id == record.id`.
