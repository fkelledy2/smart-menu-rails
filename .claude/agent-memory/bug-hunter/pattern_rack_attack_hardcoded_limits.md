---
name: Rack::Attack JWT throttles ignore per-token rate limits
description: rack_attack.rb jwt_api/token throttles hardcode limit: 60 and 1000, ignoring the rate_limit_per_minute and rate_limit_per_hour columns on each AdminJwtToken record
type: feedback
---

`config/initializers/rack_attack.rb` defines:

```ruby
Rack::Attack.throttle('jwt_api/token/minute', limit: 60, period: 60.seconds) do |req|
  ...
  token ? "jwt_token:#{token.id}:minute" : nil
end
```

The limit is hardcoded to `60` regardless of the `token.rate_limit_per_minute` value stored on the `AdminJwtToken` record. `Jwt::TokenGenerator` correctly stores per-token limits in the DB, and `AdminJwtToken` validates them, but Rack::Attack never reads them.

**Why:** Rack::Attack throttle blocks run at middleware layer before authentication; the `limit:` value is evaluated once at boot, not per-request. Dynamic per-token limits require a lambda for the `limit:` parameter (supported by rack-attack >= 6.x) or a custom throttle block that reads the token's field.

**How to apply:** Use a lambda for `limit:` — e.g. `limit: ->(req) { token&.rate_limit_per_minute || 60 }` — or accept that Rack::Attack provides coarse IP-level defence and the per-token limit is enforced at a different layer. Currently there is no application-layer per-token rate enforcement beyond Rack::Attack, so every token silently gets 60 rpm / 1000 rph regardless of what was configured at creation time.
