# frozen_string_literal: true

# Rack middleware that issues a 301 permanent redirect for all requests arriving
# on the www subdomain, forwarding them to the naked canonical domain.
#
# Design notes:
# - Inserted at position 0 (before all other Rack layers) so the response exits
#   before any database, session, or asset-pipeline work is performed.
# - Stateless: no session reads/writes, no Set-Cookie header.
# - Path and query string are preserved via Rack::Request#fullpath.
# - Only fires when Host == 'www.mellow.menu'; all other hosts fall through.
# - No redirect loop: requests to 'mellow.menu' unconditionally call @app.
class DomainRedirect
  CANONICAL_HOST = 'mellow.menu'
  WWW_HOST = 'www.mellow.menu'

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.host == WWW_HOST
      return [301, { 'Location' => "https://#{CANONICAL_HOST}#{req.fullpath}" }, []]
    end

    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(0, DomainRedirect)
