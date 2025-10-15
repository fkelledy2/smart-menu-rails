class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: %i[show edit update destroy analytics]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /employees or /employees.json
  def index
    respond_to do |format|
      format.html do
        if params[:restaurant_id]
          @futureParentRestaurant = Restaurant.find(params[:restaurant_id])

          # Use AdvancedCacheService for restaurant employees with comprehensive data
          @employees_data = AdvancedCacheService.cached_restaurant_employees(@futureParentRestaurant.id,
                                                                             include_analytics: true,)
          @employees = @employees_data[:employees]

          # Track restaurant employees view
          AnalyticsService.track_user_event(current_user, 'restaurant_employees_viewed', {
            restaurant_id: @futureParentRestaurant.id,
            restaurant_name: @futureParentRestaurant.name,
            employees_count: @employees.count,
            viewing_context: 'restaurant_management',
          },)
        else
          # Use AdvancedCacheService for user's all employees across restaurants
          @all_employees_data = AdvancedCacheService.cached_user_all_employees(current_user.id)
          @employees = @all_employees_data[:employees]

          # Track all employees view
          AnalyticsService.track_user_event(current_user, 'all_employees_viewed', {
            user_id: current_user.id,
            restaurants_count: @all_employees_data[:metadata][:restaurants_count],
            total_employees: @employees.count,
          },)
        end
      end

      format.json do
        # For JSON requests, use optimized queries with minimal includes
        if params[:restaurant_id]
          @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
          @employees = policy_scope(@futureParentRestaurant.employees.where(archived: false).order(:sequence))
        else
          # Get employees from all user's restaurants
          restaurant_ids = current_user.restaurants.pluck(:id)
          @employees = policy_scope(Employee.where(restaurant_id: restaurant_ids, archived: false).order(:sequence))
        end
        
        # Use minimal JSON view for better performance
        render 'index_minimal'
      end
    end
  end

  # GET /employees/1 or /employees/1.json
  def show
    authorize @employee

    respond_to do |format|
      format.html do
        # Use AdvancedCacheService for comprehensive employee data with analytics
        @employee_data = AdvancedCacheService.cached_employee_with_details(@employee.id)
      end

      format.json do
        # For JSON requests, @employee is already set by before_action and is an ActiveRecord object
        # No additional setup needed - the JSON view will work with the ActiveRecord object
      end
    end

    # Track employee view
    AnalyticsService.track_user_event(current_user, 'employee_viewed', {
      employee_id: @employee.id,
      employee_name: @employee.name,
      restaurant_id: @employee.restaurant_id,
      employee_role: @employee.role,
      viewing_context: 'employee_management',
    },)
  end

  # GET /employees/1/analytics
  def analytics
    authorize @employee, :show?

    # Get analytics period from params or default to 30 days for employee context
    days = params[:days]&.to_i || 30

    # Use AdvancedCacheService for employee performance analytics
    @analytics_data = AdvancedCacheService.cached_employee_performance(@employee.id, days: days)

    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'employee_analytics_viewed', {
      employee_id: @employee.id,
      employee_name: @employee.name,
      restaurant_id: @employee.restaurant_id,
      period_days: days,
    },)

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /restaurants/:restaurant_id/employees/summary
  def summary
    @restaurant = Restaurant.find(params[:restaurant_id])
    authorize Employee.new(restaurant: @restaurant), :index?

    # Get summary period from params or default to 30 days
    days = params[:days]&.to_i || 30

    # Use AdvancedCacheService for restaurant employee summary
    @summary_data = AdvancedCacheService.cached_restaurant_employee_summary(@restaurant.id, days: days)

    # Track summary view
    AnalyticsService.track_user_event(current_user, 'restaurant_employee_summary_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      total_employees: @summary_data[:summary][:total_employees],
      active_employees: @summary_data[:summary][:active_employees],
    },)

    respond_to do |format|
      format.html
      format.json { render json: @summary_data }
    end
  end

  # GET /employees/new
  def new
    @employee = Employee.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @employee.restaurant = @futureParentRestaurant
    end
    authorize @employee
  end

  # GET /employees/1/edit
  def edit
    authorize @employee
  end

  # POST /employees or /employees.json
  def create
    @employee = Employee.new(employee_params)
    authorize @employee

    respond_to do |format|
      if @employee.save
        @employee.email = @employee.user.email
        format.html do
          redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.created')
        end
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/1 or /employees/1.json
  def update
    authorize @employee

    respond_to do |format|
      if @employee.update(employee_params)
        # Invalidate AdvancedCacheService caches for this employee
        AdvancedCacheService.invalidate_employee_caches(@employee.id)
        AdvancedCacheService.invalidate_restaurant_caches(@employee.restaurant_id)
        AdvancedCacheService.invalidate_user_caches(@employee.restaurant.user_id) if @employee.restaurant.user_id

        @employee.email = @employee.user.email
        format.html do
          redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.updated')
        end
        # format.html { redirect_to @return_url, notice: "Employee was successfully updated." }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1 or /employees/1.json
  def destroy
    authorize @employee

    # Store data for cache invalidation before archiving
    restaurant_id = @employee.restaurant_id
    user_id = @employee.restaurant.user_id

    @employee.update(archived: true)

    # Invalidate AdvancedCacheService caches for this employee
    AdvancedCacheService.invalidate_employee_caches(@employee.id)
    AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
    AdvancedCacheService.invalidate_user_caches(user_id) if user_id

    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.deleted')
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_employee
    if current_user
      @employee = Employee.find(params[:id])
      if @employee.nil? || (@employee.restaurant.user != current_user)
        redirect_to root_url
      end
    else
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def employee_params
    # Remove dangerous mass assignment parameters (user_id, restaurant_id, role)
    # These should be set explicitly in controller actions, not via mass assignment
    params.require(:employee).permit(:name, :eid, :image, :status, :sequence)
  end
end
