class OrdritemsController < ApplicationController
  before_action :set_ordritem, only: %i[ show edit update destroy ]

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
        format.html { redirect_to ordritem_url(@ordritem), notice: "Ordritem was successfully created." }
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
        format.html { redirect_to ordritem_url(@ordritem), notice: "Ordritem was successfully updated." }
        format.json { render :show, status: :ok, location: @ordritem }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_ordritem
      @ordritem = Ordritem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ordritem_params
      params.require(:ordritem).permit(:ordr_id, :menuitem_id, :ordritemprice, :status)
    end
end
