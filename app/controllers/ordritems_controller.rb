class OrdritemsController < ApplicationController
  before_action :set_ordritem, only: %i[ show edit update destroy ]
  before_action :set_currency

  # GET /ordritems or /ordritems.json
  def index
    if current_user
        @ordritems = []
        Ordr.joins(:restaurant).where(restaurant: {user: current_user}).each do |ordr|
            @ordritems += Ordritem.where( ordr: ordr).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /ordritems/1 or /ordritems/1.json
  def show
  end

  # GET /ordritems/new
  def new
    @ordritem = Ordritem.new
  end

  # GET /ordritems/1/edit
  def edit
  end

  # POST /ordritems or /ordritems.json
  def create
    @ordritem = Ordritem.new(ordritem_params)
    respond_to do |format|
      ActiveRecord::Base.transaction do
        if @ordritem.save
          adjust_inventory(@ordritem.menuitem&.inventory, -1)
          @ordrparticipant = find_or_create_participant(@ordritem.ordr)
          Ordraction.create!(ordrparticipant: @ordrparticipant, ordr: @ordritem.ordr, ordritem: @ordritem, action: 2)
          update_ordr(@ordritem.ordr)
          broadcast_partials(@ordritem.ordr, @ordritem.ordr.tablesetting, @ordrparticipant)
          format.html { redirect_to restaurant_ordrs_path(@ordritem.ordr.restaurant), notice: "Ordritem was successfully created." }
          format.json { render :show, status: :created, location: @ordritem }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ordritem.errors, status: :unprocessable_entity }
        end
      end
    end
  end


  # PATCH/PUT /ordritems/1 or /ordritems/1.json
  def update
    respond_to do |format|
      ActiveRecord::Base.transaction do
        old_ordritem = @ordritem.dup
        if @ordritem.update(ordritem_params)
          # If menuitem_id changed, adjust old/new inventory
          if old_ordritem.menuitem_id != @ordritem.menuitem_id
            adjust_inventory(old_ordritem.menuitem&.inventory, 1)
            adjust_inventory(@ordritem.menuitem&.inventory, -1)
          end
          update_ordr(@ordritem.ordr)
          broadcast_partials(@ordritem.ordr, @ordritem.ordr.tablesetting, find_or_create_participant(@ordritem.ordr))
          format.json { render :show, status: :ok, location: @ordritem }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @ordritem.errors, status: :unprocessable_entity }
        end
      end
    end
  end


  # DELETE /ordritems/1 or /ordritems/1.json
  def destroy
    ActiveRecord::Base.transaction do
      adjust_inventory(@ordritem.menuitem&.inventory, 1)
      order = @ordritem.ordr
      @ordritem.destroy!
      update_ordr(order)
      ordrparticipant = find_or_create_participant(order)
      Ordraction.create!(ordrparticipant: ordrparticipant, ordr: order, ordritem: @ordritem, action: 3)
      broadcast_partials(order, order.tablesetting, ordrparticipant)
      respond_to do |format|
        format.html { redirect_to ordritems_url, notice: "Ordritem was successfully destroyed." }
        format.json { head :no_content }
      end
    end
  end

  private

  def adjust_inventory(inventory, delta)
    return unless inventory
    inventory.with_lock do
      inventory.currentinventory += delta
      inventory.currentinventory = 0 if inventory.currentinventory < 0
      inventory.currentinventory = inventory.startinginventory if inventory.currentinventory > inventory.startinginventory
      inventory.save!
    end
  end

  def find_or_create_participant(ordr)
    if current_user
      Ordrparticipant.where(ordr: ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s).first_or_create do |participant|
        participant.ordr = ordr
        participant.employee = @current_employee
        participant.role = 1
        participant.sessionid = session.id.to_s
      end
    else
      Ordrparticipant.where(ordr: ordr, role: 0, sessionid: session.id.to_s).first_or_create do |participant|
        participant.ordr = ordr
        participant.role = 0
        participant.sessionid = session.id.to_s
      end
    end
  end

  def broadcast_partials(ordr, tablesetting, ordrparticipant)
    # Eager load all associations needed by partials to prevent N+1 queries
    ordr = Ordr.includes(menu: [:restaurant, :menusections, :menuavailabilities]).find(ordr.id)
    menu = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
    allergyns = Allergyn.where(restaurant_id: restaurant.id)
    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    full_refresh = ordr.status == 'closed'
    ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant

    partials = {
      context: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: {
            order: ordr,
            menu: menu,
            ordrparticipant: ordrparticipant,
            tablesetting: tablesetting,
            menuparticipant: menuparticipant,
            current_employee: @current_employee
          }
        )
      ),
      modals: compress_string(
        Rails.cache.fetch([
          :show_modals,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          tablesetting.try(:id),
          menuparticipant.try(:id),
          restaurant_currency.code,
          @current_employee.try(:id)
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: ordr,
              menu: menu,
              ordrparticipant: ordrparticipant,
              tablesetting: tablesetting,
              menuparticipant: menuparticipant,
              restaurantCurrency: restaurant_currency,
              current_employee: @current_employee
            }
          )
        end
      ),
      menuContentStaff: compress_string(
        Rails.cache.fetch([
          :menu_content_staff,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          ordrparticipant.try(:id),
          menuparticipant.try(:id)
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant
            }
          )
        end
      ),
      menuContentCustomer: compress_string(
        Rails.cache.fetch([
          :menu_content_customer,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          ordrparticipant.try(:id),
          menuparticipant.try(:id)
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant
            }
          )
        end
      ),
      orderCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderCustomer',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant
          }
        )
      ),
      orderStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant
          }
        )
      ),
      tableLocaleSelectorStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorStaff',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
            menuparticipant: menuparticipant
          }
        )
      ),
      tableLocaleSelectorCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorCustomer',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
            menuparticipant: menuparticipant
          }
        )
      ),
      fullPageRefresh: { refresh: full_refresh }
    }
    ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)
  end

  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end


    # Use callbacks to share common setup or constraints between actions.
    def set_ordritem
      @ordritem = Ordritem.find(params[:id])
    end

    def update_ordr( ordr )
        ordr.nett = ordr.runningTotal
        taxes = Tax.where(restaurant_id: ordr.restaurant.id).order(sequence: :asc)
        totalTax = 0
        totalService = 0
        for tax in taxes do
            if tax.taxtype == 'service'
                totalService += ((tax.taxpercentage * ordr.nett)/100)
            else
                totalTax += ((tax.taxpercentage * ordr.nett)/100)
            end
        end
        ordr.tax = totalTax
        ordr.service = totalService
        ordr.gross = ordr.nett + ordr.tip + ordr.service + ordr.tax
        ordr.save
    end

    def set_currency
      if params[:id]
          @ordritem = Ordritem.find(params[:id])
          if @ordritem.ordr.restaurant.currency
            @restaurantCurrency = ISO4217::Currency.from_code(@ordritem.ordr.restaurant.currency)
          else
            @restaurantCurrency = ISO4217::Currency.from_code('USD')
          end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def ordritem_params
      params.require(:ordritem).permit(:ordr_id, :menuitem_id, :ordritemprice, :status)
    end
end
