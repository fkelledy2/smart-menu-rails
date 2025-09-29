require 'rqrcode'

class MenusController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_menu, only: %i[show edit update destroy regenerate_images]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i
    if current_user
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menus = policy_scope(Menu).where(restaurant_id: @restaurant.id, archived: false)
          .includes([:genimage])
          .includes([:menuavailabilities])
          .order(:sequence).all
      else
        @menus = policy_scope(Menu).where(archived: false).order(:sequence)
          .includes([:genimage])
          .includes([:menuavailabilities])
          .all
      end
      Analytics.track(
        user_id: current_user.id,
        event: 'menus.index',
      )
    elsif params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @menus = Menu.where(restaurant: @restaurant).all
      @tablesettings = @restaurant.tablesettings
      Analytics.track(
        event: 'menus.index',
        properties: {
          restaurant_id: @menus.restaurant.id,
        },
      )
    end
  end

  # POST /menus/:id/regenerate_images
  def regenerate_images
    authorize @menu, :update?

    if @menu.nil?
      redirect_to root_url and return
    end

    scope = Genimage.where(menu_id: @menu.id)
    queued = 0
    scope.find_each do |genimage|
      next if genimage.menuitem&.itemtype == 'wine'

      # Prefer async to avoid blocking the request
      GenerateImageJob.perform_async(genimage.id)
      queued += 1
    end

    flash[:notice] = t('menus.controller.image_regeneration_queued', count: queued)
    redirect_to edit_menu_path(@menu)
  end

  # GET	/restaurants/:restaurant_id/menus/:menu_id/tablesettings/:id(.:format)	menus#show
  # GET	/restaurants/:restaurant_id/menus/:id(.:format)	 menus#show
  # GET /menus/1 or /menus/1.json
  def show
    # Public access for customer viewing, but authorize if user is logged in
    authorize @menu if current_user
    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
        end
        Analytics.track(
          event: 'menus.show',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
      end
      @participantsFirstTime = false
      @tablesetting = Tablesetting.find_by(id: params[:id])
      @openOrder = Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                              restaurant_id: @tablesetting.restaurant_id, status: 0,)
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 20,))
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 30,)).first
      if @openOrder
        @openOrder.nett = @openOrder.runningTotal
        taxes = Tax.where(restaurant_id: @openOrder.restaurant.id).order(sequence: :asc)
        totalTax = 0
        totalService = 0
        taxes.each do |tax|
          if tax.taxtype == 'service'
            totalService += ((tax.taxpercentage * @openOrder.nett) / 100)
          else
            totalTax += ((tax.taxpercentage * @openOrder.nett) / 100)
          end
        end
        @openOrder.tax = totalTax
        @openOrder.service = totalService
        @openOrder.gross = @openOrder.nett + @openOrder.tip + @openOrder.service + @openOrder.tax
        if current_user
          @ep = Ordrparticipant.where(ordr: @openOrder, employee: @current_employee, role: 1,
                                      sessionid: session.id.to_s,).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr: @openOrder, employee: @current_employee, role: 1,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
          end
        else
          @ep = Ordrparticipant.where(ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr_id: @openOrder.id, role: 0,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
            @ordraction = Ordraction.new(ordrparticipant_id: @ordrparticipant.id, ordr: @openOrder, action: 0)
          else
            @ordrparticipant = @ep
            @ordraction = Ordraction.new(ordrparticipant: @ep, ordr: @openOrder, action: 0)
          end
          @ordraction.save
        end
      end
    else
      @menu = Menu.find_by(id: params[:id])
      @allergyns = Allergyn.where(restaurant_id: @menu.restaurant.id)
    end
  end

  # GET /menus/new
  def new
    @menu = Menu.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @menu.restaurant = @futureParentRestaurant
    end
    authorize @menu

    Analytics.track(
      user_id: current_user.id,
      event: 'menus.new',
      properties: {
        restaurant_id: @menu.restaurant&.id,
      },
    )
  end

  # GET /menus/1/edit
  def edit
    authorize @menu

    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
        end
      end
      Analytics.track(
        event: 'menus.edit',
        properties: {
          restaurant_id: @menu.restaurant.id,
          menu_id: @menu.id,
        },
      )
    end
    @qrURL = Rails.application.routes.url_helpers.menu_url(@menu, host: request.host_with_port)
    @qrURL.sub! 'http', 'https'
    @qrURL.sub! '/edit', ''
    @qr = RQRCode::QRCode.new(@qrURL)
  end

  # POST /menus or /menus.json
  def create
    @menu = Menu.new(menu_params)
    authorize @menu

    respond_to do |format|
      # Remove PDF if requested
      if (params[:menu][:remove_pdf_menu_scan] == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.save
        Analytics.track(
          user_id: current_user.id,
          event: 'menus.create',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuSyncJob.start'
        SmartMenuSyncJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuSyncJob.end'
        format.html do
          redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.menu'))
        end
        format.json { render :show, status: :created, location: @menu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menus/1 or /menus/1.json
  def update
    authorize @menu

    respond_to do |format|
      # Remove PDF if requested
      if (params[:menu][:remove_pdf_menu_scan] == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.update(menu_params)
        Analytics.track(
          user_id: current_user.id,
          event: 'menus.update',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuSyncJob.start'
        SmartMenuSyncJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuSyncJob.end'
        format.html do
          redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
        end
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menus/1 or /menus/1.json
  def destroy
    authorize @menu

    @menu.update(archived: true)
    Analytics.track(
      user_id: current_user.id,
      event: 'menus.destroy',
      properties: {
        restaurant_id: @menu.restaurant.id,
        menu_id: @menu.id,
      },
    )
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.menu'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_menu
    @menu = Menu.find(params[:menu_id] || params[:id])
    if current_user && (@menu.nil? || (@menu.restaurant.user != current_user))
      redirect_to root_url
    end
    @restaurantCurrency = ISO4217::Currency.from_code(@menu.restaurant.currency || 'USD')
    @canAddMenuItem = false
    if @menu && current_user
      @menuItemCount = @menu.menuitems.count
      if @menuItemCount < current_user.plan.itemspermenu || current_user.plan.itemspermenu == -1
        @canAddMenuItem = true
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def menu_params
    params.require(:menu).permit(:name, :description, :image, :remove_image, :pdf_menu_scan, :status, :sequence,
                                 :restaurant_id, :displayImages, :displayImagesInPopup, :allowOrdering, :inventoryTracking, :imagecontext, :covercharge,)
  end
end
