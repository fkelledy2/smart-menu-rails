class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: %i[ show edit update destroy ]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /employees or /employees.json
  def index
    if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @employees = policy_scope(Employee).where(restaurant: @futureParentRestaurant, archived: false).all
    else
        @employees = policy_scope(Employee).where(archived: false).all
    end
  end

  # GET /employees/1 or /employees/1.json
  def show
    authorize @employee
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
            format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.created') }
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
            @employee.email = @employee.user.email
            format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.updated') }
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
    
    @employee.update( archived: true )
    respond_to do |format|
      format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: t('employees.controller.deleted') }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_employee
        begin
            if current_user
                @employee = Employee.find(params[:id])
                if( @employee == nil or @employee.restaurant.user != current_user )
                    redirect_to root_url
                end
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def employee_params
      params.require(:employee).permit(:name, :eid, :image, :role, :user_id, :status, :sequence, :restaurant_id)
    end
end
