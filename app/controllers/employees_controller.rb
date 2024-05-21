class EmployeesController < ApplicationController
  before_action :set_employee, only: %i[ show edit update destroy ]

  # GET /employees or /employees.json
  def index
    if current_user
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @employees = Employee.joins(:restaurant).where(restaurant: @futureParentRestaurant).all
        else
            @employees = Employee.joins(:restaurant).where(restaurant: {user: current_user}).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /employees/1 or /employees/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /employees/new
  def new
    if current_user
        @employee = Employee.new
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @employee.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /employees/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /employees or /employees.json
  def create
    if current_user
        @employee = Employee.new(employee_params)
        respond_to do |format|
          if @employee.save
            @employee.email = @employee.user.email
            format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: "Employee was successfully created." }
            format.json { render :show, status: :created, location: @employee }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @employee.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /employees/1 or /employees/1.json
  def update
    if current_user
        respond_to do |format|
          if @employee.update(employee_params)
            @employee.email = @employee.user.email
            format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: "Employee was successfully updated." }
            # format.html { redirect_to @return_url, notice: "Employee was successfully updated." }
            format.json { render :show, status: :ok, location: @employee }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @employee.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /employees/1 or /employees/1.json
  def destroy
    if current_user
        @employee.destroy!
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(id: @employee.restaurant.id), notice: "Employee was successfully deleted." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_employee
        begin
            if current_user
                @employee = Employee.find(params[:id])
                if( @employee == nil or @employee.restaurant.user != current_user )
                    redirect_to home_url
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
      params.require(:employee).permit(:name, :eid, :image, :role, :user_id, :status, :restaurant_id)
    end
end
