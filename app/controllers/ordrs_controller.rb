class OrdrsController < ApplicationController
  before_action :set_ordr, only: %i[ show edit update destroy ]

  # GET /ordrs or /ordrs.json
  def index
    @ordrs = Ordr.all
  end

  # GET /ordrs/1 or /ordrs/1.json
  def show
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
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id, action: 1 );
                @ordrparticipant.save
            else
                @existingParticipant = Ordrparticipant.where( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s ).first
                if @existingParticipant == nil
                    cookies["existingParticipant"] = false
                    @existingParticipant = cookies["existingParticipant"]
                else
                    cookies["existingParticipant"] = true
                    @existingParticipant = cookies["existingParticipant"]
                end
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id, action: 1 );
                @ordrparticipant.save
            end
        end
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully created." }
        format.json { render :show, status: :created, location: @ordr }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordr.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordrs/1 or /ordrs/1.json
  def update
    respond_to do |format|
      if( ordr_params[:status] = 2 )
          @ordr.nett = @ordr.runningTotal
      end

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
      @ordr.tip = ordr_params[:tip]
      @ordr.tax = totalTax
      @ordr.service = totalService
      @ordr.gross = @ordr.nett + @ordr.tip + @ordr.service + @ordr.tax

      if @ordr.update(ordr_params)
        if( ordr_params[:status] = 0 )
            if current_user
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id, action: 1 );
                @ordrparticipant.save
            else
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id, action: 1 );
                @ordrparticipant.save
            end
        end
        if( ordr_params[:status] = 2 )
            if current_user
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, employee: @current_employee, role: 1, sessionid: session.id, action: 5 );
                @ordrparticipant.save
            else
                @ordrparticipant = Ordrparticipant.new( ordr: @ordr, role: 0, sessionid: session.id, action: 5 );
                @ordrparticipant.save
            end
        end
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully updated." }
        format.json { render :show, status: :ok, location: @ordr }
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

    # Only allow a list of trusted parameters through.
    def ordr_params
      params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :status, :employee_id, :tablesetting_id, :menu_id, :restaurant_id)
    end
end
