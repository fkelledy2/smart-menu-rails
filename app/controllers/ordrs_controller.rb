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
            taxes = Tax.where(restaurant_id: @ordr.restaurant.id).includes([:ordrparticipants]).order(sequence: :asc)
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
            @ordr.tax = totalTax
            @ordr.service = totalService
            @ordr.gross = @ordr.nett + @ordr.tip + @ordr.service + @ordr.tax
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
            @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
            @tablesetting.status = 0
            @tablesetting.save
            ActionCable.server.broadcast("ordr_channel", @ordr)
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
#       if( ordr_params[:status] = 10 )
          @ordr.nett = @ordr.runningTotal
#       end
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
      if ordr_params[:tip]
        @ordr.tip = ordr_params[:tip]
      else
        @ordr.tip = 0
      end
      @ordr.tax = totalTax
      @ordr.service = totalService
      @ordr.gross = @ordr.nett + @ordr.tip + @ordr.service + @ordr.tax

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
            @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
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
            @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
            @tablesetting.status = 1
            @tablesetting.save
            @ordr.ordritems.each do |oi|
                if oi.status = 10
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
            @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
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
            @tablesetting = Tablesetting.find_by_id(@ordr.tablesetting.id)
            @tablesetting.status = 0
            @tablesetting.save
        end
        ActionCable.server.broadcast("ordr_channel", @ordr)
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully updated." }
        format.json { render :show, status: :ok, location: @ordr }
#         format.turbo_stream
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
      params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :status, :employee_id, :tablesetting_id, :menu_id, :restaurant_id)
    end
end
