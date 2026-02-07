class Payments::PaymentProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  def update
    authorize @restaurant, :update?

    profile = PaymentProfile.find_or_initialize_by(restaurant: @restaurant)
    profile.primary_provider ||= :stripe

    requested_merchant_model = payment_profile_params[:merchant_model]
    stripe_enabled = ProviderAccount.exists?(restaurant: @restaurant, provider: :stripe, status: :enabled)

    if requested_merchant_model.present? && stripe_enabled
      profile.update!(merchant_model: requested_merchant_model)
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings'), notice: 'Payments settings updated'
    else
      redirect_back fallback_location: edit_restaurant_path(@restaurant, section: 'settings')
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def payment_profile_params
    params.fetch(:payment_profile, {}).permit(:merchant_model)
  end
end
