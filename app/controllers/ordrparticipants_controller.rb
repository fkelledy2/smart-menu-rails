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
            @smartMenu = Smartmenu.where( restaurant_id: @ordrparticipant.ordr.menu.restaurant.id, menu_id: @ordrparticipant.ordr.menu.id, tablesetting_id: @ordrparticipant.ordr.tablesetting.id ).first
            format.html { redirect_to smartmenu_path(@smartMenu.slug), notice: "Ordrparticipant was successfully created." }
            format.json { render :show, status: :created, location: @ordrparticipant }
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
            @smartMenu = Smartmenu.where( restaurant_id: @ordrparticipant.ordr.menu.restaurant.id, menu_id: @ordrparticipant.ordr.menu.id, tablesetting_id: @ordrparticipant.ordr.tablesetting.id ).first
            format.html { redirect_to smartmenu_path(@smartMenu.slug), notice: "Ordrparticipant was successfully updated." }
            format.json { render :show, status: :ok, location: @ordrparticipant }
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
      params.require(:ordrparticipant).permit(:sessionid, :action, :role, :employee_id, :ordr_id, :ordritem_id, :name, allergyn_ids: [])
    end
end
