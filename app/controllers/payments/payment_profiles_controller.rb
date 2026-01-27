class Payments::PaymentProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  def update
    authorize @restaurant, :update?

    acct = ProviderAccount.find_by(restaurant: @restaurant, provider: :stripe)
    unless acct&.status.to_s == 'enabled'
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: 'Complete Stripe Connect onboarding before changing merchant of record.'
      return
    end

    profile = PaymentProfile.find_or_create_by!(restaurant: @restaurant) do |p|
      p.merchant_model = :restaurant_mor
      p.primary_provider = :stripe
    end

    merchant_model = params.dig(:payment_profile, :merchant_model).presence
    if merchant_model.blank? || !merchant_model.to_s.in?(PaymentProfile.merchant_models.keys)
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), alert: 'Invalid merchant model'
      return
    end

    profile.update!(merchant_model: merchant_model)
    redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), notice: 'Payments settings updated'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
end
