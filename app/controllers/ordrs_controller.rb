class OrdrsController < ApplicationController
  before_action :set_ordr, only: %i[ show edit update destroy ]
  before_action :set_currency

  # GET /ordrs or /ordrs.json
  def index
    if current_user
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @ordrs = Ordr.joins(:restaurant).where(restaurant_id: @restaurant.id).all
        else
            @ordrs = Ordr.joins(:restaurant).where(restaurant: {user: current_user}).all
        end

        for @ordr in @ordrs do
            remainingItems =  @ordr.orderedItemsCount + @ordr.preparedItemsCount
            if remainingItems == 0
                @ordr.status = 25
            end
            @ordr.nett = @ordr.runningTotal
            taxes = Tax.where(restaurant_id: @ordr.restaurant.id).includes([:restaurant]).order(sequence: :asc)
            totalTax = 0
            totalService = 0
            for tax in taxes do
                if tax.taxtype == 'service'
                    totalService += ((tax.taxpercentage * @ordr.nett)/100)
                else
                    totalTax += ((tax.taxpercentage * @ordr.nett)/100)
                end
            end
            @ordr.tax = totalTax
            @ordr.service = totalService
            @ordr.gross = @ordr.nett + @ordr.tip + @ordr.service + @ordr.tax
        end
    else
        redirect_to root_url
    end
  end

  # GET /ordrs/1 or /ordrs/1.json
  def show
            @ordr.nett = @ordr.runningTotal
            taxes = Tax.where(restaurant_id: @ordr.restaurant.id).order(sequence: :asc)
            totalTax = 0
            totalService = 0
            for tax in taxes do
                if tax.taxtype == 'service'
                    totalService += ((tax.taxpercentage * @ordr.nett)/100)
                else
                    totalTax += ((tax.taxpercentage * @ordr.nett)/100)
                end
            end
            @ordr.covercharge = @ordr.ordercapacity * @ordr.menu.covercharge
            @ordr.tax = totalTax
            @ordr.service = totalService
            @ordr.gross = @ordr.nett + @ordr.covercharge + @ordr.tip + @ordr.service + @ordr.tax
  end

  # GET /ordrs/new
  def new
    @ordr = Ordr.new
    @ordr.nett = 0
    @ordr.tip = 0
    @ordr.service = 0
    @ordr.tax = 0
    @ordr.gross = 0
    @ordr.ordrparticipants ||= []
    @ordr.ordritems ||= []
  end

  # GET /ordrs/1/edit
  def edit
  end

  # POST /ordrs or /ordrs.json
  def create
    @ordr = Ordr.new(ordr_params)
    @ordr.nett = 0
    @ordr.tip = 0
    @ordr.service = 0
    @ordr.tax = 0
    @ordr.gross = 0

    respond_to do |format|
      if @ordr.save
        @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
        if( ordr_params[:status] = 0 )
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s);
                    @ordrparticipant.save
                end
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    cookies["existingParticipant"] = false
                    @existingParticipant = cookies["existingParticipant"]
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                else
                    cookies["existingParticipant"] = true
                    @existingParticipant = cookies["existingParticipant"]
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, action: 1)
                @ordraction.save
            end
            @tablesetting.status = 0
            @tablesetting.save
            broadcast_partials( @ordr, @tablesetting, @ordrparticipant, true )
        end
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully created." }
        format.json { render :show, status: :created, location: @ordr }
#         format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordr.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordrs/1 or /ordrs/1.json
  def update
    respond_to do |format|
      @ordr.nett = @ordr.runningTotal
      taxes = Tax.where(restaurant_id: @ordr.restaurant.id).order(sequence: :asc)
      totalTax = 0
      totalService = 0
      @ordr.covercharge = @ordr.ordercapacity * @ordr.menu.covercharge
      for tax in taxes do
        if tax.taxtype == 'service'
            totalService += ((tax.taxpercentage * (@ordr.nett+@ordr.covercharge))/100)
        else
            totalTax += ((tax.taxpercentage * (@ordr.nett+@ordr.covercharge))/100)
        end
      end
      if ordr_params[:tip]
        @ordr.tip = ordr_params[:tip]
      else
        @ordr.tip = 0
      end
      @ordr.tax = totalTax
      @ordr.service = totalService
      @ordr.gross = @ordr.nett + @ordr.covercharge + @ordr.tip + @ordr.service + @ordr.tax

      if( ordr_params[:status] = 20 )
          @ordr.orderedAt = Time.now
      end
      if( ordr_params[:status] = 30 )
          @ordr.billRequestedAt = Time.now
      end
      if( ordr_params[:status] = 40 )
          @ordr.paidAt = Time.now
      end
      if @ordr.update(ordr_params)
        @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
        if( ordr_params[:status] = 0 )
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, action: 1)
                @ordraction.save
            end
            @tablesetting.status = 0
            @tablesetting.save
        end
        if( ordr_params[:status] = 20 )
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, action: 5)
                @ordraction.save
            end
            @tablesetting.status = 1
            @tablesetting.save
            @ordr.ordritems.each do |oi|
                if oi.status == 'added'
                    oi.status = 20
                    oi.save
                end
            end
        end
        if( ordr_params[:status] = 30 )
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, action: 5)
                @ordraction.save
            end
            @tablesetting.status = 1
            @tablesetting.save
        end
        if( ordr_params[:status] = 40 )
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, action: 5)
                @ordraction.save
            end
            @tablesetting.status = 0
            @tablesetting.save
        end
        fullRefresh = false
        if @ordr.status == 'closed'
            fullRefresh = true
        end
        format.json { render :show, status: :ok, location: @ordr }
        broadcast_partials( @ordr, @tablesetting, @ordrparticipant, fullRefresh )
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordr.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordrs/1 or /ordrs/1.json
  def destroy
    @ordr.destroy!

    respond_to do |format|
      format.html { redirect_to ordrs_url, notice: "Ordr was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def broadcast_partials(ordr, tablesetting, ordrparticipant, full_refresh)
      # Eager load all associations needed by partials to prevent N+1 queries
      ordr = Ordr.includes(menu: [:restaurant, :menusections, :menuavailabilities]).find(ordr.id)
      menu = ordr.menu
      restaurant = menu.restaurant
      menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
      allergyns = Allergyn.where(restaurant_id: restaurant.id)
      restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
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

    private

    def compress_string(str)
      require 'zlib'
      require 'base64'
      Base64.strict_encode64(Zlib::Deflate.deflate(str))
    end


    # Use callbacks to share common setup or constraints between actions.
    def set_ordr
      @ordr = Ordr.find(params[:id])
    end

    def set_currency
      if params[:restaurant_id]
          @restaurant = Restaurant.find(params[:restaurant_id])
          if @restaurant.currency
            @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
          else
            @restaurantCurrency = ISO4217::Currency.from_code('USD')
          end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def ordr_params
      params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :status, :ordercapacity, :covercharge, :employee_id, :tablesetting_id, :menu_id, :restaurant_id)
    end
end
