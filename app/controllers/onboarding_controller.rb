class OnboardingController < ApplicationController
  include AnalyticsTrackable

  skip_around_action :switch_locale

  before_action :authenticate_user!
  before_action :set_onboarding_session
  before_action :redirect_if_complete
  before_action :track_onboarding_start, only: [:show], if: -> { @onboarding&.started? }

  # Pundit authorization
  after_action :verify_authorized

  # GET /onboarding
  # Single-page form: user name + restaurant name → creates restaurant → redirects to restaurant edit
  def show
    authorize @onboarding
    render :account_details
  end

  # PATCH/POST /onboarding
  def update
    authorize @onboarding
    handle_account_details
  end

  private

  def redirect_if_complete
    return if request.format.json?

    # If user already has a restaurant, skip onboarding entirely
    if current_user.restaurants.exists?(archived: false)
      complete_onboarding_session!
      redirect_to edit_restaurant_path(current_user.restaurants.where(archived: false).first)
      return
    end

    if current_user.onboarding_complete?
      redirect_to root_path
    end
  end

  def set_onboarding_session
    @onboarding = current_user.onboarding_session
    @onboarding ||= current_user.create_onboarding_session(status: :started)
    # Reload to get a mutable object (IdentityCache returns frozen objects)
    @onboarding = @onboarding.reload if @onboarding.persisted? && @onboarding.frozen?
  end

  def handle_account_details
    # Update user's basic info first (name)
    unless current_user.update(account_params)
      AnalyticsService.track_onboarding_step_failed(current_user, 1, current_user.errors.full_messages.join(', '))
      return render :account_details
    end

    # Require a restaurant name
    restaurant_name = params.dig(:onboarding_session, :restaurant_name).to_s.strip
    if restaurant_name.blank?
      AnalyticsService.track_onboarding_step_failed(current_user, 1, 'restaurant_name missing')
      flash.now[:alert] = I18n.t('onboarding.account_details.restaurant_name_required', default: 'Please enter a restaurant name to continue.')
      return render :account_details
    end

    # Find or create the restaurant for this user
    restaurant = current_user.restaurants.where('LOWER(name) = ?', restaurant_name.downcase).first
    new_restaurant = false
    unless restaurant
      restaurant = current_user.restaurants.create!(
        name: restaurant_name,
        archived: false,
        status: 0,
      )
      new_restaurant = true
    end

    # Link onboarding to restaurant and mark as completed
    @onboarding.update!(restaurant: restaurant)
    complete_onboarding_session!

    RestaurantProvisioningService.call(restaurant: restaurant, user: current_user) if new_restaurant

    # Track successful completion
    AnalyticsService.track_onboarding_step_completed(current_user, 1, {
      name: current_user.name,
      email: current_user.email,
      restaurant_id: restaurant.id,
      restaurant_new: new_restaurant,
    })

    if new_restaurant
      AnalyticsService.track_user_event(current_user, 'restaurant_onboarding_started', {
        restaurant_id: restaurant.id,
        source: 'signup_onboarding',
        initial_next_section: restaurant.onboarding_next_section,
      })
    end

    # Redirect to the restaurant edit page — go-live checklist is the canonical onboarding now
    flash[:notice] = I18n.t('onboarding.next_steps.restaurant_edit_notice', default: 'Great! Complete the go-live checklist to get your restaurant online.')
    redirect_to edit_restaurant_path(restaurant, onboarding: true), status: :see_other
  end

  # Mark the onboarding session as completed so the user is never redirected back here
  def complete_onboarding_session!
    return if @onboarding.completed?

    @onboarding.completed! if @onboarding.respond_to?(:completed!)
  end

  def account_params
    params.require(:user).permit(:name)
  end

  def track_onboarding_start
    AnalyticsService.track_onboarding_started(current_user, params[:source])
  end

  # Override from AnalyticsTrackable to skip page tracking for JSON requests
  def should_track_page_view?
    super && !request.format.json?
  end
end
