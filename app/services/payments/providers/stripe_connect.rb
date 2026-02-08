require 'stripe'

module Payments
  module Providers
    class StripeConnect
      def initialize(restaurant:)
        @restaurant = restaurant
      end

      def receipt_details_for_account(provider_account_id:)
        ensure_api_key!

        acct = Stripe::Account.retrieve(provider_account_id.to_s)
        business_profile = acct.respond_to?(:business_profile) ? acct.business_profile : nil
        settings = acct.respond_to?(:settings) ? acct.settings : nil
        payments_settings = settings.respond_to?(:payments) ? settings.payments : nil

        {
          account_id: acct.id.to_s,
          business_name: business_profile.respond_to?(:name) ? business_profile.name.to_s.presence : nil,
          support_email: business_profile.respond_to?(:support_email) ? business_profile.support_email.to_s.presence : nil,
          support_phone: business_profile.respond_to?(:support_phone) ? business_profile.support_phone.to_s.presence : nil,
          support_url: business_profile.respond_to?(:support_url) ? business_profile.support_url.to_s.presence : nil,
          support_address: business_profile.respond_to?(:support_address) ? business_profile.support_address : nil,
          statement_descriptor: payments_settings.respond_to?(:statement_descriptor) ? payments_settings.statement_descriptor.to_s.presence : nil,
        }
      rescue Stripe::StripeError => e
        Rails.logger.warn("[StripeConnect] receipt_details_for_account failed restaurant_id=#{@restaurant&.id} account_id=#{provider_account_id}: #{e.class}: #{e.message}")
        nil
      rescue StandardError => e
        Rails.logger.warn("[StripeConnect] receipt_details_for_account failed restaurant_id=#{@restaurant&.id} account_id=#{provider_account_id}: #{e.class}: #{e.message}")
        nil
      end

      def start_onboarding!(return_url:, refresh_url:)
        ensure_api_key!

        profile = PaymentProfile.find_or_create_by!(restaurant: @restaurant) do |p|
          p.merchant_model = :restaurant_mor
          p.primary_provider = :stripe
        end

        account = ProviderAccount.find_by(restaurant: @restaurant, provider: :stripe)

        if account.nil?
          country = profile.default_country.presence || @restaurant.country.presence || 'US'

          created = Stripe::Account.create(
            type: 'express',
            country: country.to_s.upcase,
            metadata: { restaurant_id: @restaurant.id },
            capabilities: {
              card_payments: { requested: true },
              transfers: { requested: true },
            },
          )

          account = ProviderAccount.create!(
            restaurant: @restaurant,
            provider: :stripe,
            provider_account_id: created.id.to_s,
            account_type: created.type.to_s,
            country: created.country.to_s.presence,
            currency: created.default_currency.to_s.presence&.upcase,
            status: :onboarding,
            capabilities: created.capabilities || {},
            payouts_enabled: !created.payouts_enabled.nil?,
          )
        end

        link = Stripe::AccountLink.create(
          account: account.provider_account_id,
          type: 'account_onboarding',
          return_url: return_url,
          refresh_url: refresh_url,
        )

        link.url.to_s
      end

      private

      def ensure_api_key!
        return if Stripe.api_key.present?

        key = begin
          Rails.application.credentials.stripe_secret_key
        rescue StandardError
          nil
        end

        if key.blank?
          key = begin
            Rails.application.credentials.dig(:stripe, :secret_key) ||
              Rails.application.credentials.dig(:stripe, :api_key)
          rescue StandardError
            nil
          end
        end

        key = ENV.fetch('STRIPE_SECRET_KEY', nil) if key.blank?

        raise 'Stripe is not configured' if key.blank?

        Stripe.api_key = key
      end
    end
  end
end
