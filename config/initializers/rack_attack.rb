# frozen_string_literal: true

# Rate limiting and request throttling via Rack::Attack
# https://github.com/rack/rack-attack

Rack::Attack.enabled = !Rails.env.test?

# Cache store — must use a shared store so limits are enforced across all
# processes/dynos. MemoryStore is per-process and ineffective in production.
Rack::Attack.cache.store = begin
  if Rails.env.production? && ENV['REDIS_URL'].present?
    ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', nil), namespace: 'rack_attack')
  else
    ActiveSupport::Cache::MemoryStore.new
  end
rescue Gem::LoadError, LoadError
  ActiveSupport::Cache::MemoryStore.new
end

# ----------------------------------------------------------------------------
# Throttles
# ----------------------------------------------------------------------------

# Login: 5 attempts per email per 60 seconds
Rack::Attack.throttle('logins/email', limit: 5, period: 60.seconds) do |req|
  if req.path == '/users/sign_in' && req.post?
    # Normalize the email to prevent bypasses
    req.params.dig('user', 'email')&.to_s&.downcase&.strip
  end
end

# Login: 20 attempts per IP per 60 seconds
Rack::Attack.throttle('logins/ip', limit: 20, period: 60.seconds) do |req|
  req.ip if req.path == '/users/sign_in' && req.post?
end

# Password reset: 5 per email per hour
Rack::Attack.throttle('password_reset/email', limit: 5, period: 1.hour) do |req|
  if req.path == '/users/password' && req.post?
    req.params.dig('user', 'email')&.to_s&.downcase&.strip
  end
end

# Account registration: 3 per IP per hour
Rack::Attack.throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
  req.ip if req.path == '/users' && req.post?
end

# API endpoints: 60 requests per minute per IP
Rack::Attack.throttle('api/ip', limit: 60, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/api/')
end

# JWT API tokens: per-token rate limit, honouring the rate_limit_per_minute /
# rate_limit_per_hour fields configured at token creation time.
# Uses the SHA-256 hash of the raw JWT as the throttle key to avoid storing
# sensitive material in the cache. Token lookup is cached by IdentityCache
# where available so the double lookup (limit + key) does not hit the DB twice.
# If the token is unknown the request will fail at auth anyway; this is defence-in-depth.

jwt_token_for = lambda do |req|
  auth = req.get_header('HTTP_AUTHORIZATION').to_s
  return nil unless req.path.start_with?('/api/') && auth.start_with?('Bearer ')

  raw_jwt = auth.split(' ', 2).last.presence
  return nil unless raw_jwt

  AdminJwtToken.find_by(token_hash: Digest::SHA256.hexdigest(raw_jwt))
rescue StandardError
  nil
end

Rack::Attack.throttle('jwt_api/token/minute',
                      limit: ->(req) { jwt_token_for.call(req)&.rate_limit_per_minute || 60 },
                      period: 60.seconds) do |req|
  token = jwt_token_for.call(req)
  token ? "jwt_token:#{token.id}:minute" : nil
end

Rack::Attack.throttle('jwt_api/token/hour',
                      limit: ->(req) { jwt_token_for.call(req)&.rate_limit_per_hour || 1000 },
                      period: 1.hour) do |req|
  token = jwt_token_for.call(req)
  token ? "jwt_token:#{token.id}:hour" : nil
end

# Anonymous analytics: 30 per minute per IP
Rack::Attack.throttle('analytics/ip', limit: 30, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/api/v1/analytics/track_anonymous')
end

# Stripe webhooks: 100 per minute per IP (generous for burst deliveries)
Rack::Attack.throttle('webhooks/ip', limit: 100, period: 60.seconds) do |req|
  req.ip if req.path == '/payments/webhooks/stripe' && req.post?
end

# General request throttle: 300 per minute per IP
Rack::Attack.throttle('requests/ip', limit: 300, period: 60.seconds) do |req|
  req.ip unless req.path.start_with?('/assets/', '/packs/')
end

# ----------------------------------------------------------------------------
# Receipt delivery throttles
# ----------------------------------------------------------------------------

# Self-service receipt request: 5 per email per 10 minutes — prevents receipt spamming
Rack::Attack.throttle('receipts/email', limit: 5, period: 10.minutes) do |req|
  if req.path == '/receipts/request' && req.post?
    req.params['recipient_email']&.to_s&.downcase&.strip
  end
end

# Self-service receipt request: 10 per IP per 10 minutes
Rack::Attack.throttle('receipts/ip', limit: 10, period: 10.minutes) do |req|
  req.ip if req.path == '/receipts/request' && req.post?
end

# ----------------------------------------------------------------------------
# QR Security throttles
# ----------------------------------------------------------------------------

# Order creation: 10 per IP per 5 minutes — prevents order flooding from a single IP
Rack::Attack.throttle('orders/ip', limit: 10, period: 5.minutes) do |req|
  req.ip if req.path.include?('/ordritems') && req.post?
end

# Order creation per dining session: 20 per 10 minutes — per-session order rate limit
Rack::Attack.throttle('orders/session', limit: 20, period: 10.minutes) do |req|
  if req.path.include?('/ordritems') && req.post?
    # Extract dining session token from cookie-based session if present
    # We use the raw cookie string since Rack::Attack runs before ActionDispatch
    cookie_header = req.get_header('HTTP_COOKIE').to_s
    match = cookie_header.match(/_session=([^;]+)/)
    match ? "session:#{match[1][0, 32]}" : nil
  end
end

# Smartmenu page loads: 30 per IP per minute — prevents scraping / rapid token enumeration
Rack::Attack.throttle('smartmenus/ip', limit: 30, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/smartmenus/', '/t/')
end

# QR token endpoint: 60 per IP per minute — prevents token brute-force while allowing
# normal use (table switching, refreshes). Token space is 2^256 so enumeration is
# computationally infeasible; this throttle is defence-in-depth only.
Rack::Attack.throttle('table_tokens/ip', limit: 60, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/t/') && req.get?
end

# Auto Pay: payment method storage — 10 per IP per 5 minutes
# Prevents automated card enumeration via the payment_method_ref endpoint.
Rack::Attack.throttle('auto_pay/payment_methods/ip', limit: 10, period: 5.minutes) do |req|
  req.ip if req.path =~ %r{/payment_methods$} && req.post?
end

# Auto Pay: capture — 20 per IP per 10 minutes
Rack::Attack.throttle('auto_pay/capture/ip', limit: 20, period: 10.minutes) do |req|
  req.ip if req.path =~ %r{/capture$} && req.post?
end

# ----------------------------------------------------------------------------
# Demo booking throttles
# ----------------------------------------------------------------------------

# Demo booking submission: 5 per IP per hour — prevents automated lead spam
Rack::Attack.throttle('demo_bookings/ip', limit: 5, period: 1.hour) do |req|
  req.ip if req.path == '/demo_bookings' && req.post?
end

# Video analytics: 60 per IP per minute — generous to allow rapid event firing
Rack::Attack.throttle('video_analytics/ip', limit: 60, period: 60.seconds) do |req|
  req.ip if req.path == '/demo_bookings/video_analytics' && req.post?
end

# ----------------------------------------------------------------------------
# CRM webhook throttles
# ----------------------------------------------------------------------------

# Calendly webhook: 60 per minute per IP — defence-in-depth alongside HMAC verification
Rack::Attack.throttle('crm/calendly_webhook/ip', limit: 60, period: 60.seconds) do |req|
  req.ip if req.path == '/admin/webhooks/calendly' && req.post?
end

# ----------------------------------------------------------------------------
# Marketing QR code throttles
# ----------------------------------------------------------------------------

# Marketing QR resolve: 60 per IP per minute — prevents token scraping.
# Token space is UUID (128-bit) so enumeration is computationally infeasible;
# this throttle is defence-in-depth only.
Rack::Attack.throttle('marketing_qr/ip', limit: 60, period: 60.seconds) do |req|
  req.ip if req.path.start_with?('/m/') && req.get?
end

# ----------------------------------------------------------------------------
# Customer Concierge throttles
# ----------------------------------------------------------------------------

# Concierge query: 10 per hour per session — controls OpenAI API cost and prevents abuse.
# Uses the first 32 characters of the encrypted session cookie as the throttle key,
# consistent with the orders/session throttle pattern above.
Rack::Attack.throttle('concierge/session', limit: 10, period: 1.hour) do |req|
  if req.path =~ %r{/t/[^/]+/concierge/query} && req.post?
    cookie_header = req.get_header('HTTP_COOKIE').to_s
    match = cookie_header.match(/_session=([^;]+)/)
    match ? "concierge_session:#{match[1][0, 32]}" : req.ip
  end
end

# Concierge: 60 per hour per IP — broad defence in depth
Rack::Attack.throttle('concierge/ip', limit: 60, period: 1.hour) do |req|
  req.ip if req.path =~ %r{/t/[^/]+/concierge/query} && req.post?
end

# ----------------------------------------------------------------------------
# Blocklists
# ----------------------------------------------------------------------------

# Block requests from known bad user agents
Rack::Attack.blocklist('bad_user_agents') do |req|
  Rack::Attack::Fail2Ban.filter("bad_ua:#{req.ip}", maxretry: 0, findtime: 1.day, bantime: 1.day) do
    CGI.unescape(req.user_agent.to_s) =~ /\b(sqlmap|nikto|nmap|masscan)\b/i
  end
end

# ----------------------------------------------------------------------------
# Response bodies
# ----------------------------------------------------------------------------

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env['rack.attack.match_data'] || {})[:period]
  [
    429,
    { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
    [{ error: { code: 'rate_limited', message: 'Too many requests. Please try again later.' } }.to_json],
  ]
end
