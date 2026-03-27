# Mellow Admin JWT Token Management

## Status
- Priority Rank: #8
- Category: Post-Launch
- Effort: L
- Dependencies: Existing admin authentication (`admin?` and `super_admin?` predicates), existing REST API surface (confirm API v1/v2 coverage before building)

## Problem Statement
Enterprise and tech-savvy restaurant groups need programmatic access to mellow.menu data (menus, orders, analytics) to integrate with their own systems — POS integrations, inventory management, loyalty platforms, and reporting tools. Currently there is no authenticated API access for third parties. JWT token management gives mellow.menu admins the ability to provision secure, scoped API access per restaurant, enabling integration partnerships and enterprise sales.

## Success Criteria
- A mellow.menu admin can generate a JWT token for a specific restaurant with configurable scopes and expiry.
- The token is delivered securely to the restaurant manager.
- All API endpoints protected by JWT tokens enforce scope-based access control.
- Tokens can be revoked immediately.
- All token operations are audit-logged.
- API response times are within 200ms for standard reads.

## User Stories
- As a mellow.menu admin, I want to generate a scoped JWT token for a restaurant so they can integrate mellow.menu with their systems.
- As a restaurant manager, I want to receive my API token securely with documentation on how to use it.
- As a mellow.menu admin, I want to revoke a token immediately if it is compromised.
- As a developer integrating with mellow.menu, I want clear API documentation and scope definitions.

## Functional Requirements
1. Admin-only UI under `/admin/jwt_tokens`: list, create, view, revoke, send/download tokens.
2. Token generation: configurable expiry (30/60/90 days or custom), API scopes (per the scope matrix below), rate limit per token (requests per minute/hour).
3. Only `@mellow.menu` email users with `admin: true` can access token management.
4. JWT structure includes: `iss`, `sub`, `aud`, `exp`, `iat`, `jti`, `restaurant_id`, `admin_user_id`, `scopes`, `rate_limit`.
5. Token is stored as a hash only — the raw JWT is shown once at creation and cannot be retrieved again.
6. Token delivery: email to restaurant manager OR secure one-time download link (expires in 24 hours).
7. `admin_jwt_tokens` table: `admin_user_id`, `restaurant_id`, `token_hash`, `name`, `description`, `scopes` (jsonb), `expires_at`, `revoked_at`, `last_used_at`, `usage_count`.
8. `jwt_token_usage_logs` table: `jwt_token_id`, `endpoint`, `method`, `ip_address`, `response_status`, `created_at`.
9. API scope definitions (v1):
   - `menu:read` — read menus, sections, items
   - `menu:write` — create and update menu items
   - `orders:read` — read order data
   - `orders:write` — update order status
   - `analytics:read` — read analytics data
   - `settings:read` — read restaurant settings
10. All JWT-protected API endpoints must validate: token signature, expiry, restaurant scope, action scope. Reject with 401 if any check fails.
11. Rate limiting per token is enforced at the application layer (Rack::Attack or middleware) using the token's `jti` as the key.
12. Renewal: admin can generate a new token for the same restaurant/scope combination. Old token remains valid until its expiry or explicit revocation.

## Non-Functional Requirements
- JWT signed with RS256 or HS256 (confirm algorithm choice — RS256 preferred for auditable key management).
- Token hash stored using a secure one-way hash (e.g. SHA-256 of the raw JWT).
- All admin token management pages require `admin: true`.
- Usage logs retained for 90 days minimum.
- API endpoints must respond within 200ms (excluding network) for standard reads.

## Technical Notes

### Services
- `app/services/jwt/token_generator.rb`: generates signed JWT with configured claims.
- `app/services/jwt/token_validator.rb`: validates incoming JWT (signature, expiry, scope).
- `app/services/jwt/scope_enforcer.rb`: checks action-level scope against token claims.

### Models / Migrations
- `create_admin_jwt_tokens`: see schema above. Indexes on `[token_hash]`, `[restaurant_id]`, `[admin_user_id]`.
- `create_jwt_token_usage_logs`: see schema above. Index on `[jwt_token_id, created_at]`.

### Policies
- `app/policies/admin_jwt_token_policy.rb`: restrict to `user.admin? && user.email.ends_with?('@mellow.menu')`.

### Middleware / Concern
- `app/controllers/concerns/jwt_authenticated.rb`: `before_action` concern for JWT-protected API endpoints; validates and sets `current_api_restaurant` and `current_token_scopes`.

### Jobs
- `app/jobs/jwt_token_expiry_notification_job.rb`: notify admin 7 days before token expiry.

### API Endpoints (JWT-protected, new or existing)
```
GET  /api/v1/restaurants/:id/menus
GET  /api/v1/restaurants/:id/orders
GET  /api/v1/restaurants/:id/analytics/dashboard
```
- Add scope enforcement to existing API controllers via the `JwtAuthenticated` concern.

### Admin Routes
```ruby
namespace :admin do
  resources :jwt_tokens do
    member do
      post :revoke
      post :send_email
      get  :download_link
    end
  end
end
```

### Flipper
- `jwt_api_access` — feature flag to enable JWT-protected endpoints before full rollout.

## Acceptance Criteria
1. Admin can create a token with selected scopes and expiry; raw JWT is displayed once and cannot be retrieved again.
2. API call with valid token and matching scope returns 200.
3. API call with valid token but wrong scope returns 403.
4. API call with expired token returns 401.
5. `POST /admin/jwt_tokens/:id/revoke` immediately invalidates the token (all subsequent API calls with that token return 401).
6. Each successful and failed API call is logged to `jwt_token_usage_logs`.
7. Token email delivery sends the raw JWT in a secure email with usage instructions.
8. A non-admin user cannot access any `/admin/jwt_tokens` route (returns 403 or redirect).
9. Rate limit per token: requests exceeding configured limit return 429.

## Out of Scope
- Interactive Swagger/OpenAPI documentation (post-launch).
- Postman collection generation (post-launch).
- Restaurant self-service token management (post-launch — admin-issued only in v1).
- IP whitelisting (post-launch).
- Bulk token operations (post-launch).

## Open Questions
1. Which API endpoints already exist in a `/api/v1/` or `/api/v2/` namespace? Audit the routes file before building to avoid duplicating existing endpoints.
2. Should JWT tokens use RS256 (asymmetric, more enterprise-friendly) or HS256 (simpler, symmetric)? Recommend RS256 with a managed keypair stored in Rails credentials.
3. What is the token expiry policy for enterprise customers — should there be a "non-expiring" option for machine-to-machine integrations?
4. Is Swagger/OpenAPI documentation required before any customer can use the API, or can v1 ship with markdown documentation only?
