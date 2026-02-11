class RestaurantClaimRequestsController < ApplicationController
  skip_before_action :set_current_employee
  skip_before_action :set_permissions
  skip_before_action :redirect_to_onboarding_if_needed
  skip_around_action :switch_locale

  before_action :set_restaurant

  def new
    @claim_request = RestaurantClaimRequest.new
  end

  def create
    @claim_request = @restaurant.restaurant_claim_requests.new(claim_request_params)
    @claim_request.status = :started
    @claim_request.initiated_by_user = current_user if user_signed_in?

    if @claim_request.save
      redirect_to submitted_restaurant_claim_requests_path(@restaurant),
                  notice: 'Your claim request has been submitted. Our team will review it shortly.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def submitted
    # Thank-you / confirmation page
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def claim_request_params
    params.require(:restaurant_claim_request).permit(:claimant_email, :claimant_name, :verification_method, :evidence)
  end
end
