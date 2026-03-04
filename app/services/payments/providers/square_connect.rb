# frozen_string_literal: true

module Payments
  module Providers
    # Square OAuth flow: authorize, exchange, revoke, refresh.
    # Mirrors Payments::Providers::StripeConnect.
    class SquareConnect
      def initialize(restaurant:)
        @restaurant = restaurant
      end

      # Build the Square OAuth authorize URL for the restaurant owner to visit.
      def authorize_url(redirect_uri:, state:)
        params = {
          client_id: SquareConfig.client_id,
          scope: SquareConfig.oauth_scopes.join('+'),
          session: false,
          state: state,
          redirect_uri: redirect_uri,
        }
        "#{SquareConfig.oauth_base_url}/authorize?#{params.to_query}"
      end

      # Exchange an authorization code for access + refresh tokens.
      # Stores encrypted tokens in ProviderAccount, fetches merchant profile.
      def exchange_code!(code:, redirect_uri:)
        response = oauth_post('/token', {
          client_id: SquareConfig.client_id,
          client_secret: SquareConfig.client_secret,
          code: code,
          grant_type: 'authorization_code',
          redirect_uri: redirect_uri,
        })

        merchant_id = response['merchant_id']
        access_token = response['access_token']
        refresh_token = response['refresh_token']
        expires_at = response['expires_at'].present? ? Time.parse(response['expires_at']) : nil
        short_lived = response['short_lived'] || false

        # Ensure payment profile exists
        PaymentProfile.find_or_create_by!(restaurant: @restaurant) do |p|
          p.merchant_model = :restaurant_mor
          p.primary_provider = :square
        end

        # Create or update ProviderAccount
        account = ProviderAccount.find_or_initialize_by(
          restaurant: @restaurant,
          provider: :square,
        )
        account.assign_attributes(
          access_token: access_token,
          refresh_token: refresh_token,
          token_expires_at: expires_at,
          environment: SquareConfig.environment,
          scopes: SquareConfig.oauth_scopes.join(' '),
          connected_at: Time.current,
          disconnected_at: nil,
          status: :enabled,
        )
        account.save!

        # Fetch merchant profile and store merchant_id
        @restaurant.update!(
          payment_provider: 'square',
          payment_provider_status: :connected,
          square_merchant_id: merchant_id,
          square_application_id: SquareConfig.app_id,
          square_oauth_revoked_at: nil,
        )

        # Fetch locations for the merchant
        locations = fetch_locations(access_token: access_token)

        # Auto-select if only one location
        if locations.length == 1
          @restaurant.update!(square_location_id: locations.first['id'])
        end

        { account: account, locations: locations, merchant_id: merchant_id }
      end

      # Revoke OAuth tokens and mark restaurant as disconnected.
      def revoke!
        account = ProviderAccount.find_by(restaurant: @restaurant, provider: :square)
        return false unless account

        begin
          oauth_post('/revoke', {
            client_id: SquareConfig.client_id,
            access_token: account.access_token,
          }, auth: "Client #{SquareConfig.client_secret}")
        rescue StandardError => e
          Rails.logger.warn("[SquareConnect] revoke failed restaurant_id=#{@restaurant.id}: #{e.message}")
        end

        account.update!(
          disconnected_at: Time.current,
          status: :disabled,
        )

        @restaurant.update!(
          payment_provider_status: :disconnected,
          square_oauth_revoked_at: Time.current,
        )

        true
      end

      # Refresh an expiring access token using the refresh token.
      def refresh_token!(provider_account: nil)
        account = provider_account || ProviderAccount.find_by!(restaurant: @restaurant, provider: :square)

        response = oauth_post('/token', {
          client_id: SquareConfig.client_id,
          client_secret: SquareConfig.client_secret,
          refresh_token: account.refresh_token,
          grant_type: 'refresh_token',
        })

        account.update!(
          access_token: response['access_token'],
          refresh_token: response['refresh_token'],
          token_expires_at: response['expires_at'].present? ? Time.parse(response['expires_at']) : nil,
        )

        account
      end

      # Fetch Square locations for the connected merchant.
      def fetch_locations(access_token: nil)
        token = access_token || ProviderAccount.find_by!(restaurant: @restaurant, provider: :square).access_token
        client = SquareHttpClient.new(access_token: token, environment: SquareConfig.environment)
        response = client.get('/locations')
        response['locations'] || []
      end

      private

      def oauth_post(path, body, auth: nil)
        url = "#{SquareConfig.oauth_base_url}#{path}"
        headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Square-Version' => SquareConfig.api_version,
        }
        headers['Authorization'] = auth if auth.present?

        response = HTTParty.post(url, headers: headers, body: body.to_json, timeout: 15)
        parsed = response.parsed_response

        unless response.success?
          errors = parsed.is_a?(Hash) ? parsed['errors'] || parsed['message'] : response.body
          raise SquareHttpClient::SquareApiError.new(
            "Square OAuth error: #{errors}",
            status_code: response.code,
            errors: Array(errors),
          )
        end

        parsed
      end
    end
  end
end
