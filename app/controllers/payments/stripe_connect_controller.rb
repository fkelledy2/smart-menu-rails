class Payments::StripeConnectController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  def start
    authorize @restaurant, :update?

    url = Payments::Providers::StripeConnect.new(restaurant: @restaurant).start_onboarding!(
      return_url: restaurant_payments_stripe_connect_return_url(@restaurant),
      refresh_url: restaurant_payments_stripe_connect_refresh_url(@restaurant),
    )

    redirect_to url, allow_other_host: true
  rescue Stripe::InvalidRequestError => e
    Rails.logger.warn("Stripe Connect onboarding failed for restaurant_id=#{@restaurant.id}: #{e.message}")
    flash[:stripe_connect_error] = 'Stripe Connect is not enabled for this Stripe account. Enable Connect in the Stripe Dashboard and try again.'
    redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error])
  rescue RuntimeError => e
    raise unless e.message.to_s == 'Stripe is not configured'

    flash[:stripe_connect_error] = 'Stripe is not configured. Set STRIPE_SECRET_KEY (or credentials) and try again.'
    redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error])
  end

  def refresh
    authorize @restaurant, :update?

    url = Payments::Providers::StripeConnect.new(restaurant: @restaurant).start_onboarding!(
      return_url: restaurant_payments_stripe_connect_return_url(@restaurant),
      refresh_url: restaurant_payments_stripe_connect_refresh_url(@restaurant),
    )

    redirect_to url, allow_other_host: true
  rescue Stripe::InvalidRequestError => e
    Rails.logger.warn("Stripe Connect refresh failed for restaurant_id=#{@restaurant.id}: #{e.message}")
    flash[:stripe_connect_error] = 'Stripe Connect is not enabled for this Stripe account. Enable Connect in the Stripe Dashboard and try again.'
    redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error])
  rescue RuntimeError => e
    raise unless e.message.to_s == 'Stripe is not configured'

    flash[:stripe_connect_error] = 'Stripe is not configured. Set STRIPE_SECRET_KEY (or credentials) and try again.'
    redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error])
  end

  def return
    authorize @restaurant, :update?

    # Check if Stripe account is fully onboarded and enable ordering/payments
    begin
      provider_account = ProviderAccount.find_by(restaurant: @restaurant, provider: :stripe)
      if provider_account.present?
        acct = Stripe::Account.retrieve(provider_account.provider_account_id)
        if acct.charges_enabled && acct.payouts_enabled
          provider_account.update!(status: :active, payouts_enabled: true)
          @restaurant.update!(payments_enabled: true, ordering_enabled: true)

          # Upgrade claim_status if restaurant was soft_claimed
          if @restaurant.soft_claimed?
            @restaurant.update!(claim_status: :claimed)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.warn("[StripeConnect] return: account check failed for restaurant_id=#{@restaurant.id}: #{e.class}: #{e.message}")
    end

    redirect_to edit_restaurant_path(@restaurant, section: 'settings')
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
end
