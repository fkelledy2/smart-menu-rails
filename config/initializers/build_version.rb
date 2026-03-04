# frozen_string_literal: true

# Computed once at boot and used as part of HTTP cache keys (ETags) so that
# every deployment automatically invalidates browser-cached pages.
#
# Production (Heroku): uses HEROKU_RELEASE_VERSION or HEROKU_SLUG_COMMIT.
# Development:         uses a static "dev" token — cache keys stay stable
#                      across restarts so page reloads stay fast.

BUILD_VERSION = (
  ENV['HEROKU_RELEASE_VERSION'] ||
  ENV['HEROKU_SLUG_COMMIT']&.slice(0, 8) ||
  ENV['GIT_COMMIT']&.slice(0, 8) ||
  ENV['BUILD_VERSION'] ||
  (Rails.env.production? ? SecureRandom.hex(4) : 'dev')
).freeze
