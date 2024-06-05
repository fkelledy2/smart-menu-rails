class MenusectionsController < ApplicationController
  before_action :set_menusection, only: %i[ show edit update destroy ]

  # GET /menusections or /menusections.json
  def index
    if current_user
        @menusections = []
        puts params[:menu_id]
        if params[:menu_id]
          @menu = Menu.find_by_id(params[:menu_id])
          @menusections += @menu.menusections
        else
          Restaurant.where( user: current_user, archived: false).each do |restaurant|
            @menusections += restaurant.menusections
          end
        end
    else
        redirect_to root_url
    end
  end

  # GET /menusections/1 or /menusections/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /menusections/new
  def new
    if current_user
        @menusection = Menusection.new
    else
        redirect_to root_url
    end
  end

  # GET /menusections/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /menusections or /menusections.json
  def create
    if current_user
        @menusection = Menusection.new(menusection_params)
        respond_to do |format|
          if @menusection.save
            format.html { redirect_to menusection_url(@menusection), notice: "Menusection was successfully created." }
            format.json { render :show, status: :created, location: @menusection }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @menusection.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /menusections/1 or /menusections/1.json
  def update
    if current_user
        respond_to do |format|
          if @menusection.update(menusection_params)
            format.html { redirect_to menusection_url(@menusection), notice: "Menusection was successfully updated." }
            format.json { render :show, status: :ok, location: @menusection }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @menusection.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /menusections/1 or /menusections/1.json
  def destroy
    if current_user
        @menusection.update( archived: true )
        respond_to do |format|
          format.html { redirect_to menusections_url, notice: "Menusection was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menusection
        begin
            if current_user
                @menusection = Menusection.find(params[:id])
                if( @menusection == nil or @menusection.menu.restaurant.user != current_user )
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
    def menusection_params
      params.require(:menusection).permit(:name, :description, :image, :status, :sequence, :menu_id)
    end
end
