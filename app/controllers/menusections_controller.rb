class MenusectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menusection, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_for_json?

  # GET /menusections or /menusections.json
  def index
    if params[:menu_id]
      @menu = Menu.find_by(id: params[:menu_id])
      
      # Optimize query based on request format
      @menusections = if request.format.json?
                        # JSON: Direct association without expensive includes
                        @menu.menusections.order(:sequence)
                      else
                        # HTML: Full policy scope
                        policy_scope(Menusection).where(menu: @menu)
                      end
    else
      @menusections = []
    end
    
    # Use minimal JSON view for better performance
    respond_to do |format|
      format.html # Default HTML view
      format.json { render 'index_minimal' } # Use optimized minimal JSON view
    end
  end

  # GET /menusections/1 or /menusections/1.json
  def show
    authorize @menusection
  end

  # GET /menusections/new
  def new
    @menusection = Menusection.new
    if params[:menu_id]
      @futureParentMenu = Menu.find(params[:menu_id])
      @menusection.menu = @futureParentMenu
      @menusection.sequence = 1
    end
    authorize @menusection
  end

  # GET /menusections/1/edit
  def edit
    authorize @menusection
  end

  # POST /menusections or /menusections.json
  def create
    begin
      @menusection = Menusection.new(menusection_params)
      authorize @menusection

      respond_to do |format|
      if @menusection.save
        if @menusection.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menusection.menu.restaurant
          @genimage.menu = @menusection.menu
          @genimage.menusection = @menusection
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        format.html do
          redirect_to edit_restaurant_menu_url(@menusection.menu.restaurant, @menusection.menu),
                      notice: t('common.flash.created', resource: t('activerecord.models.menusection'))
        end
        format.json { render :show, status: :created, location: restaurant_menu_menusection_url(@menusection.menu.restaurant, @menusection.menu, @menusection) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menusection.errors, status: :unprocessable_entity }
      end
    end
    rescue ArgumentError => e
      # Handle invalid enum values
      @menusection = Menusection.new
      @menusection.errors.add(:status, e.message)
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menusection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menusections/1 or /menusections/1.json
  def update
    authorize @menusection

    respond_to do |format|
      if @menusection.update(menusection_params)
        if @menusection.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menusection.menu.restaurant
          @genimage.menu = @menusection.menu
          @genimage.menusection = @menusection
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        format.html do
          redirect_to edit_restaurant_menu_path(@menusection.menu.restaurant, @menusection.menu),
                      notice: t('common.flash.updated', resource: t('activerecord.models.menusection'))
        end
        format.json { render :show, status: :ok, location: restaurant_menu_menusection_url(@menusection.menu.restaurant, @menusection.menu, @menusection) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menusection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menusections/1 or /menusections/1.json
  def destroy
    authorize @menusection

    @menusection.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_menu_path(@menusection.menu.restaurant, @menusection.menu),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.menusection'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Skip policy scope verification for optimized JSON requests
  def skip_policy_scope_for_json?
    request.format.json? && current_user.present?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menusection
    if current_user
      @menusection = Menusection.find(params[:id])
      if @menusection.nil? || (@menusection.menu.restaurant.user != current_user)
        redirect_to root_url
      end
    else
      redirect_to root_url
    end
    @canAddMenuItem = false
    if @menusection.menu && current_user
      @menuItemCount = @menusection.menu.menuitems.count
      if @menuItemCount < current_user.plan.itemspermenu || current_user.plan.itemspermenu == -1
        @canAddMenuItem = true
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def menusection_params
    params.require(:menusection).permit(:name, :description, :fromhour, :frommin, :tohour, :tomin, :restricted,
                                        :image, :remove_image, :status, :sequence, :menu_id,)
  end
end
