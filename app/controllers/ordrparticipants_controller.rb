class OrdrparticipantsController < ApplicationController
  before_action :set_ordrparticipant, only: %i[ show edit update destroy ]

  # GET /ordrparticipants or /ordrparticipants.json
  def index
    if current_user
        @ordrparticipants = []
        Ordr.joins(:restaurant).where(restaurant: {user: current_user}).each do |ordr|
            @ordrparticipants += Ordrparticipant.where( ordr: ordr).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /ordrparticipants/1 or /ordrparticipants/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /ordrparticipants/new
  def new
    if current_user
        @ordrparticipant = Ordrparticipant.new
    else
        redirect_to root_url
    end
  end

  # GET /ordrparticipants/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /ordrparticipants or /ordrparticipants.json
  def create
        @ordrparticipant = Ordrparticipant.new(ordrparticipant_params)
        respond_to do |format|
          if @ordrparticipant.save
            @tablesetting = Tablesetting.find_by_id(@ordrparticipant.ordr.tablesetting.id)
            broadcastPartials( @ordrparticipant.ordr, @tablesetting, @ordrparticipant )
            format.json { render :show, status: :ok, location: @ordrparticipant.ordr }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
          end
        end
  end

  # PATCH/PUT /ordrparticipants/1 or /ordrparticipants/1.json
  def update
        respond_to do |format|
          if @ordrparticipant.update(ordrparticipant_params)
            # Find all entries for participant with same sessionid and order_id and update the name.
            @tablesetting = Tablesetting.find_by_id(@ordrparticipant.ordr.tablesetting.id)
            broadcastPartials( @ordrparticipant.ordr, @tablesetting, @ordrparticipant )
            format.json { render :show, status: :ok, location: @ordrparticipant.ordr }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
          end
        end
  end

  # DELETE /ordrparticipants/1 or /ordrparticipants/1.json
  def destroy
    if current_user
        @ordrparticipant.destroy!
        respond_to do |format|
          format.html { redirect_to ordrparticipants_url, notice: "Ordrparticipant was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private

    def broadcastPartials(ordr, tablesetting, ordrparticipant)
      # Eager load all associations needed by partials to prevent N+1 queries
      ordr = Ordr.includes(menu: [:restaurant, :menusections, :menuavailabilities]).find(ordr.id)
      menu = ordr.menu
      restaurant = menu.restaurant
      menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
      allergyns = Allergyn.where(restaurant_id: restaurant.id)
      restaurantCurrency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
      fullRefresh = ordr.status == 'closed'
      ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant

      require 'zlib'
      require 'base64'
      
      def compress_string(str)
        Base64.strict_encode64(Zlib::Deflate.deflate(str))
      end
      
      partials = {
        context: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: { order: ordr, menu: menu, ordrparticipant: ordrparticipant, tablesetting: tablesetting, menuparticipant: menuparticipant, current_employee: @current_employee }
        )),
        modals: compress_string(Rails.cache.fetch([:show_modals, ordr.cache_key_with_version, menu.cache_key_with_version, tablesetting.try(:id), menuparticipant.try(:id), restaurantCurrency.code, @current_employee.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: { order: ordr, menu: menu, ordrparticipant: ordrparticipant, tablesetting: tablesetting, menuparticipant: menuparticipant, restaurantCurrency: restaurantCurrency, current_employee: @current_employee }
          )
        end),
        menuContentStaff: compress_string(Rails.cache.fetch([:menu_content_staff, ordr.cache_key_with_version, menu.cache_key_with_version, allergyns.maximum(:updated_at), restaurantCurrency.code, ordrparticipant.try(:id), menuparticipant.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: { order: ordr, menu: menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
          )
        end),
        menuContentCustomer: compress_string(Rails.cache.fetch([:menu_content_customer, ordr.cache_key_with_version, menu.cache_key_with_version, allergyns.maximum(:updated_at), restaurantCurrency.code, ordrparticipant.try(:id), menuparticipant.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: { order: ordr, menu: menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
          )
        end),
        orderCustomer: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/orderCustomer',
          locals: { order: ordr, menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant }
        )),
        orderStaff: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: { order: ordr, menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant }
        )),
        tableLocaleSelectorStaff: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorStaff',
          locals: { menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
        )),
        tableLocaleSelectorCustomer: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorCustomer',
          locals: { menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
        )),
        fullPageRefresh: { refresh: fullRefresh }
      }
      ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)

    end                partial: 'smartmenus/showTableLocaleSelectorStaff',
                locals: { menu: @ordrparticipant.ordr.menu, restaurant: @ordrparticipant.ordr.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            tableLocaleSelectorCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/showTableLocaleSelectorCustomer',
                locals: { menu: @ordrparticipant.ordr.menu, restaurant: @ordrparticipant.ordr.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            fullPageRefresh: { refresh: fullRefresh }
        }
        ActionCable.server.broadcast("ordr_"+menuparticipant.smartmenu.slug+"_channel", partials)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_ordrparticipant
        begin
            if current_user
                @ordrparticipant = Ordrparticipant.find(params[:id])
                if( @ordrparticipant == nil or @ordrparticipant.ordr.restaurant.user != current_user )
                    redirect_to root_url
                end
            else
                @ordrparticipant = Ordrparticipant.find(params[:id])
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end

    end

    # Only allow a list of trusted parameters through.
    def ordrparticipant_params
      params.require(:ordrparticipant).permit(:sessionid, :action, :role, :employee_id, :ordr_id, :ordritem_id, :name, :preferredlocale, allergyn_ids: [])
    end
end
