class RestaurantRemovalRequestsController < ApplicationController
  skip_before_action :set_current_employee
  skip_before_action :set_permissions
  skip_before_action :redirect_to_onboarding_if_needed
  skip_around_action :switch_locale

  before_action :set_restaurant

  def new
    @removal_request = RestaurantRemovalRequest.new
  end

  def create
    @removal_request = @restaurant.restaurant_removal_requests.new(removal_request_params)
    @removal_request.source = :public_page

    if @removal_request.save
      # Immediately unpublish the preview
      @restaurant.update!(preview_enabled: false) if @restaurant.preview_enabled?

      redirect_to submitted_restaurant_removal_requests_path(@restaurant),
                  notice: 'Your removal request has been received. The preview has been unpublished immediately.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def submitted
    # Thank-you / confirmation page
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def removal_request_params
    params.require(:restaurant_removal_request).permit(:requested_by_email, :reason)
  end
end
