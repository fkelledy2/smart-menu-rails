class Payments::PaymentProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  def update
    authorize @restaurant, :update?

    profile = PaymentProfile.find_or_initialize_by(restaurant: @restaurant)
    profile.primary_provider ||= :stripe

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
