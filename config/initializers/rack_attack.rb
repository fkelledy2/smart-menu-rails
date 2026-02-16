# frozen_string_literal: true

# Rate limiting and request throttling via Rack::Attack
# https://github.com/rack/rack-attack

Rack::Attack.enabled = !Rails.env.test?

# Cache store — use Rails cache (Redis in production, memory in dev)
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

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
