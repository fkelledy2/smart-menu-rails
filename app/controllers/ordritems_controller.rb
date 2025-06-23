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
        if @ordritem.save
            if @ordritem.menuitem.inventory
                @ordritem.menuitem.inventory.currentinventory -= 1
                if @ordritem.menuitem.inventory.currentinventory < 0
                    @ordritem.menuitem.inventory.currentinventory = 0
                end
                @ordritem.menuitem.inventory.save
            end
            if current_user
                @ordrparticipant = Ordrparticipant.where( ordr: @ordritem.ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordritem.ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordritem.ordr, ordritem: @ordritem, action: 2)
                @ordraction.save
            else
                @ordrparticipant = Ordrparticipant.where( ordr: @ordritem.ordr, role: 0, sessionid: session.id.to_s ).first
                if @ordrparticipant == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @ordritem.ordr, role: 0, sessionid: session.id.to_s );
                    @ordrparticipant.save
                end
                @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordritem.ordr, ordritem: @ordritem, action: 2)
                @ordraction.save
            end
            @uo = Ordr.find(ordritem_params[:ordr_id])
            @tablesetting = Tablesetting.find_by_id(@uo.tablesetting.id)
            update_ordr( @uo )

            broadcastPartials( @uo, @tablesetting, @ordrparticipant )

            format.html { redirect_to restaurant_ordrs_path(@ordritem.ordr.restaurant), notice: "Ordritem was successfully created." }
            format.json { render :show, status: :created, location: @ordritem }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @ordritem.errors, status: :unprocessable_entity }
          end
       end
  end

  # PATCH/PUT /ordritems/1 or /ordritems/1.json
  def update
        respond_to do |format|
          if @ordritem.update(ordritem_params)
            @uoi = Ordritem.find(params[:id])
            update_ordr( @uoi.ordr )
#             ActionCable.server.broadcast("ordr_channel", @uoi.ordr )
#             format.html { redirect_to restaurant_ordrs_path(@ordritem.ordr.restaurant), notice: "Ordritem was successfully updated ()" }
            format.json { render :show, status: :ok, location: @ordritem }
#             format.turbo_stream { render turbo_stream: turbo_stream.replace("updateOrderSpan", partial: "smartmenus/order", locals: {openOrder:@uoi.ordr, menu: @uoi.ordr.menu}) }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @ordritem.errors, status: :unprocessable_entity }
          end
        end
  end

  # DELETE /ordritems/1 or /ordritems/1.json
  def destroy
        @ordritem.destroy!
        if @ordritem.menuitem.inventory
            @ordritem.menuitem.inventory.currentinventory += 1
            if @ordritem.menuitem.inventory.currentinventory > @ordritem.menuitem.inventory.startinginventory
                @ordritem.menuitem.inventory.currentinventory = @ordritem.menuitem.inventory.startinginventory
            end
            @ordritem.menuitem.inventory.save
        end
        if current_user
            @ordrparticipant = Ordrparticipant.where( ordr: @ordritem.ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
            if @ordrparticipant == nil
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id.to_s );
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
            @ordraction = Ordraction.new( ordrparticipant: @ordrparticipant, ordr: @ordr, ordritem: @ordritem, action: 3)
            @ordraction.save
        end
        respond_to do |format|
            format.html { redirect_to ordritems_url, notice: "Ordritem was successfully destroyed." }
            format.json { head :no_content }
        end
  end

  private

    def broadcastPartials( ordr, tablesetting, ordrparticipant )
        if ordr.menu.restaurant.currency
            restaurantCurrency = ISO4217::Currency.from_code(ordr.menu.restaurant.currency)
        else
            restaurantCurrency = ISO4217::Currency.from_code('USD')
        end
        menuparticipant = Menuparticipant.where( sessionid: session.id.to_s ).first
        if menuparticipant
            ordrparticipant.preferredlocale = menuparticipant.preferredlocale
        end
        allergyns = Allergyn.where( restaurant_id: ordr.menu.restaurant.id )
        fullRefresh = false
        if ordr.status == 'closed'
            fullRefresh = true
        end
        partials = {
            context: ApplicationController.renderer.render(
                partial: 'smartmenus/showContext',
                locals: { order: ordr, menu: ordr.menu, ordrparticipant: ordrparticipant, tablesetting: tablesetting, menuparticipant: menuparticipant, current_employee: @current_employee }
            ),
            modals: ApplicationController.renderer.render(
                partial: 'smartmenus/showModals',
                locals: { order: ordr, menu: ordr.menu, ordrparticipant: ordrparticipant, tablesetting: tablesetting, menuparticipant: menuparticipant, restaurantCurrency: restaurantCurrency, current_employee: @current_employee }
            ),
            menuContentStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/showMenuContentStaff',
                locals: { order: ordr, menu: ordr.menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            menuContentCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/showMenuContentCustomer',
                locals: { order: ordr, menu: ordr.menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            orderCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/orderCustomer',
                locals: { order: ordr, menu: ordr.menu, restaurant: ordr.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant }
            ),
            orderStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/orderStaff',
                locals: { order: ordr, menu: ordr.menu, restaurant: ordr.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant }
            ),
            tableLocaleSelectorStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/showTableLocaleSelectorStaff',
                locals: { menu: @smartmenu.menu, restaurant: @smartmenu.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            tableLocaleSelectorCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/showTableLocaleSelectorCustomer',
                locals: { menu: @smartmenu.menu, restaurant: @smartmenu.menu.restaurant, tablesetting: tablesetting, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            fullPageRefresh: { refresh: fullRefresh }
        }
        ActionCable.server.broadcast("ordr_channel", partials)
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
