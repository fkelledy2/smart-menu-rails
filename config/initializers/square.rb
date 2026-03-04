# frozen_string_literal: true

# Square Payment Provider Configuration
#
# Environment variables:
#   SQUARE_ENV                          - 'production' or 'sandbox' (defaults based on Rails.env)
#   SQUARE_PROD_APP_ID                  - Production application ID
#   SQUARE_PROD_CLIENT_ID               - Production OAuth client ID
#   SQUARE_PROD_CLIENT_SECRET           - Production OAuth client secret
#   SQUARE_WEBHOOK_SIGNATURE_KEY_PROD   - Production webhook signature key
#   SQUARE_SANDBOX_APP_ID               - Sandbox application ID
#   SQUARE_SANDBOX_CLIENT_ID            - Sandbox OAuth client ID
#   SQUARE_SANDBOX_CLIENT_SECRET        - Sandbox OAuth client secret
#   SQUARE_WEBHOOK_SIGNATURE_KEY_SANDBOX - Sandbox webhook signature key
#   SQUARE_API_VERSION                  - API version pin (default: 2024-12-18)

module SquareConfig
  class << self
    def environment
      ENV.fetch('SQUARE_ENV') { Rails.env.production? ? 'production' : 'sandbox' }
    end

    def sandbox?
      environment == 'sandbox'
    end

    def production?
      environment == 'production'
    end

    def app_id
      sandbox? ? ENV['SQUARE_SANDBOX_APP_ID'] : ENV['SQUARE_PROD_APP_ID']
    end

    def client_id
      sandbox? ? ENV['SQUARE_SANDBOX_CLIENT_ID'] : ENV['SQUARE_PROD_CLIENT_ID']
    end

    def client_secret
      sandbox? ? ENV['SQUARE_SANDBOX_CLIENT_SECRET'] : ENV['SQUARE_PROD_CLIENT_SECRET']
    end

    def webhook_signature_key
      sandbox? ? ENV['SQUARE_WEBHOOK_SIGNATURE_KEY_SANDBOX'] : ENV['SQUARE_WEBHOOK_SIGNATURE_KEY_PROD']
    end

    def api_version
      ENV.fetch('SQUARE_API_VERSION', '2024-12-18')
    end

    def api_base_url
      sandbox? ? 'https://connect.squareupsandbox.com/v2' : 'https://connect.squareup.com/v2'
    end

    def oauth_base_url
      sandbox? ? 'https://connect.squareupsandbox.com/oauth2' : 'https://connect.squareup.com/oauth2'
    end

    def web_payments_sdk_url
      sandbox? ? 'https://sandbox.web.squarecdn.com/v1/square.js' : 'https://web.squarecdn.com/v1/square.js'
    end

    def configured?
      app_id.present? && client_id.present? && client_secret.present?
    end

    def oauth_scopes
      %w[
        PAYMENTS_WRITE
        PAYMENTS_READ
        MERCHANT_PROFILE_READ
        ORDERS_WRITE
        ORDERS_READ
        ONLINE_STORE_SITE_READ
      ].freeze
    end
  end
end
