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
    redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error]
  rescue RuntimeError => e
    if e.message.to_s == 'Stripe is not configured'
      flash[:stripe_connect_error] = 'Stripe is not configured. Set STRIPE_SECRET_KEY (or credentials) and try again.'
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error]
    else
      raise
    end
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
    redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error]
  rescue RuntimeError => e
    if e.message.to_s == 'Stripe is not configured'
      flash[:stripe_connect_error] = 'Stripe is not configured. Set STRIPE_SECRET_KEY (or credentials) and try again.'
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: flash[:stripe_connect_error]
    else
      raise
    end
  end

  def return
    authorize @restaurant, :update?

    redirect_to edit_restaurant_path(@restaurant, section: 'settings')
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
end
