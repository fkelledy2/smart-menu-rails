class OnboardingController < ApplicationController
  skip_around_action :switch_locale
  
  before_action :authenticate_user!
  before_action :set_onboarding_session
  before_action :redirect_if_complete
  before_action :set_step
  
  # Pundit authorization
  after_action :verify_authorized
  
  def show
    authorize @onboarding
    
    @progress = (@step / 5.0 * 100).round
    @plans = Plan.where(status: :active) if @step == 3
    
    respond_to do |format|
      format.html do
        case @step
        when 1 then render :account_details
        when 2 then render :restaurant_details  
        when 3 then render :plan_selection
        when 4 then render :menu_creation
        when 5 then render :completion
        else redirect_to onboarding_path
        end
      end
      
      format.json do
        if @onboarding.completed?
          render json: {
            completed: true,
            dashboard_url: root_path,
            menu_url: @onboarding.menu ? smartmenu_path(@onboarding.menu.smartmenus.first) : nil,
            qr_code_url: nil # Will be implemented later
          }
        else
          render json: { completed: false }
        end
      end
    end
  end
  
  def update
    authorize @onboarding
    
    case @step
    when 1 then handle_account_details
    when 2 then handle_restaurant_details
    when 3 then handle_plan_selection
    when 4 then handle_menu_creation
    else redirect_to onboarding_path
    end
  end
  
  private
  
  def set_step
    @step = params[:step]&.to_i || current_step_from_status
  end
  
  def current_step_from_status
    case @onboarding.status
    when 'started' then 1
    when 'account_created' then 2
    when 'restaurant_details' then 3
    when 'plan_selected' then 4
    when 'menu_created' then 5
    else 1
    end
  end
  
  def redirect_if_complete
    if current_user.onboarding_complete? && !request.format.json?
      redirect_to root_path 
    end
  end
  
  def set_onboarding_session
    @onboarding = current_user.onboarding_session
    @onboarding ||= current_user.create_onboarding_session(status: :started)
  end
  
  def handle_account_details
    if current_user.update(account_params)
      @onboarding.account_created!
      redirect_to onboarding_step_path(2), status: :see_other
    else
      @step = 1
      render :account_details
    end
  end
  
  def handle_restaurant_details
    @onboarding.assign_attributes(restaurant_params)
    
    if @onboarding.step_valid?(2) && @onboarding.save
      @onboarding.restaurant_details!
      redirect_to onboarding_step_path(3), status: :see_other
    else
      @step = 2
      render :restaurant_details
    end
  end
  
  def handle_plan_selection
    @onboarding.selected_plan_id = params[:plan_id]
    
    if @onboarding.step_valid?(3) && @onboarding.save
      # Update user's plan
      plan = Plan.find(@onboarding.selected_plan_id)
      current_user.update!(plan: plan)
      
      @onboarding.plan_selected!
      redirect_to onboarding_step_path(4), status: :see_other
    else
      @step = 3
      @plans = Plan.active
      render :plan_selection
    end
  end
  
  def handle_menu_creation
    @onboarding.assign_attributes(menu_params)
    
    if @onboarding.step_valid?(4) && @onboarding.save
      @onboarding.menu_created!
      
      # Create restaurant and menu in background
      CreateRestaurantAndMenuJob.perform_later(current_user.id, @onboarding.id)
      
      redirect_to onboarding_step_path(5), status: :see_other
    else
      @step = 4
      render :menu_creation
    end
  end
  
  def account_params
    params.require(:user).permit(:name)
  end
  
  def restaurant_params
    params.require(:onboarding_session).permit(:restaurant_name, :restaurant_type, :cuisine_type, :location, :phone)
  end
  
  def menu_params
    params.require(:onboarding_session).permit(:menu_name, menu_items: [:name, :price, :description])
  end
end
