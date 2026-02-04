class Payments::SubscriptionsController < ApplicationController
  require 'stripe'

  before_action :authenticate_user!

  # Pundit authorization
  after_action :verify_authorized

  def start
    restaurant = current_user.restaurants.find(params[:restaurant_id])
    authorize restaurant, :update?

    plan = current_user.plan
    unless plan
      render json: { ok: false, error: 'No plan selected' }, status: :unprocessable_entity
      return
    end

    interval = (params[:interval].presence || 'month').to_s.downcase
    interval = 'month' unless %w[month year].include?(interval)

    price_id = stripe_price_id_for_plan(plan, interval: interval)
    if price_id.blank?
      render json: { ok: false, error: 'Selected plan is not configured for billing' }, status: :unprocessable_entity
      return
    end

    ensure_stripe_api_key!

    sub = restaurant.restaurant_subscription || restaurant.build_restaurant_subscription(status: :inactive)

    stripe_customer_id = sub.stripe_customer_id.presence
    if stripe_customer_id.blank?
      customer = Stripe::Customer.create(
        email: current_user.email.to_s,
        name: current_user.name.to_s.presence,
        metadata: {
          user_id: current_user.id.to_s,
          restaurant_id: restaurant.id.to_s,
        },
      )
      stripe_customer_id = customer.id.to_s
      sub.stripe_customer_id = stripe_customer_id
      sub.save!
    end

    success_url = params[:success_url].presence || edit_restaurant_url(restaurant)
    cancel_url = params[:cancel_url].presence || edit_restaurant_url(restaurant)

    session = Stripe::Checkout::Session.create(
      mode: 'subscription',
      customer: stripe_customer_id,
      success_url: success_url,
      cancel_url: cancel_url,
      line_items: [{ price: price_id, quantity: 1 }],
      allow_promotion_codes: true,
      subscription_data: {
        metadata: {
          user_id: current_user.id.to_s,
          restaurant_id: restaurant.id.to_s,
          plan_id: plan.id.to_s,
          plan_key: plan.key.to_s,
        },
      },
      metadata: {
        user_id: current_user.id.to_s,
        restaurant_id: restaurant.id.to_s,
        plan_id: plan.id.to_s,
        plan_key: plan.key.to_s,
      },
    )

    respond_to do |format|
      format.json { render json: { ok: true, checkout_url: session.url.to_s }, status: :ok }
      format.html { redirect_to session.url.to_s, allow_other_host: true }
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue StandardError => e
    Rails.logger.warn("[SubscriptionCheckout] start failed: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'Failed to start subscription checkout' }, status: :unprocessable_entity
  end

  private

  def stripe_price_id_for_plan(plan, interval: 'month')
    if interval == 'year'
      plan.respond_to?(:stripe_price_id_year) ? plan.stripe_price_id_year : nil
    else
      plan.respond_to?(:stripe_price_id_month) ? plan.stripe_price_id_month : nil
    end
  end

  def ensure_stripe_api_key!
    return if Stripe.api_key.present?

    env_key = ENV['STRIPE_SECRET_KEY'].presence

    credentials_key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError
      nil
    end

    if credentials_key.blank?
      credentials_key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError
        nil
      end
    end

    key = if Rails.env.production?
      env_key || credentials_key
    else
      credentials_key.presence || env_key
    end

    raise 'Stripe is not configured' if key.blank?

    Stripe.api_key = key
  end
end
