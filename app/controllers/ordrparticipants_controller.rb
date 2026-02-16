class OrdrparticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:update] # Allow unauthenticated updates for smart menu
  before_action :set_restaurant, except: [:update] # Allow direct updates without restaurant context
  before_action :set_ordrparticipant, only: %i[show edit update destroy]
  before_action :set_ordrparticipant_for_direct_update, only: [:update], if: -> { params[:restaurant_id].blank? }

  # Pundit authorization
  after_action :verify_authorized, except: %i[index update] # Skip authorization for direct updates
  after_action :verify_policy_scoped, only: [:index]

  # GET /ordrparticipants or /ordrparticipants.json
  def index
    @ordrparticipants = policy_scope(Ordrparticipant)
  end

  # GET /ordrparticipants/1 or /ordrparticipants/1.json
  def show
    authorize @ordrparticipant
  end

  # GET /ordrparticipants/new
  def new
    @ordrparticipant = Ordrparticipant.new
    authorize @ordrparticipant
  end

  # GET /ordrparticipants/1/edit
  def edit
    authorize @ordrparticipant
  end

  # POST /ordrparticipants or /ordrparticipants.json
  def create
    @ordrparticipant = Ordrparticipant.new(ordrparticipant_params)
    authorize @ordrparticipant

    respond_to do |format|
      if @ordrparticipant.save
        @tablesetting = Tablesetting.find_by(id: @ordrparticipant.ordr.tablesetting.id)
        broadcast_state(@ordrparticipant.ordr, @tablesetting, @ordrparticipant)
        format.json do
          render :show, status: :ok,
                        location: restaurant_ordr_url(@ordrparticipant.ordr.restaurant, @ordrparticipant.ordr)
        end
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /ordrparticipants/1 or /ordrparticipants/1.json
  def update
    # Only authorize if user is authenticated (nested route)
    authorize @ordrparticipant if current_user

    respond_to do |format|
      if @ordrparticipant.update(ordrparticipant_params)
        # Find all entries for participant with same sessionid and order_id and update the name.
        @tablesetting = Tablesetting.find_by(id: @ordrparticipant.ordr.tablesetting.id)
        broadcast_state(@ordrparticipant.ordr, @tablesetting, @ordrparticipant)
        format.json do
          render :show, status: :ok,
                        location: restaurant_ordr_url(@ordrparticipant.ordr.restaurant, @ordrparticipant.ordr)
        end
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /ordrparticipants/1 or /ordrparticipants/1.json
  def destroy
    authorize @ordrparticipant

    @ordrparticipant.destroy!
    respond_to do |format|
      format.html do
        redirect_to ordrparticipants_url,
                    notice: t('common.flash.deleted', resource: t('activerecord.models.ordrparticipant'))
      end
      format.json { head :no_content }
    end
  end

  private

  def broadcast_state(ordr, tablesetting, ordrparticipant)
    menu = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)

    payload = SmartmenuState.for_context(
      menu: menu,
      restaurant: restaurant,
      tablesetting: tablesetting,
      open_order: ordr,
      ordrparticipant: ordrparticipant,
      menuparticipant: menuparticipant,
      session_id: session.id.to_s,
    )

    # Broadcast to order-specific channel
    ActionCable.server.broadcast("ordr_#{ordr.id}_channel", { state: payload })

    # Also broadcast to slug channel for pre-order subscribers
    if menuparticipant&.smartmenu&.slug
      ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", { state: payload })
    end
  rescue StandardError => e
    Rails.logger.warn("[BroadcastState][Ordrparticipants] Broadcast failed: #{e.class}: #{e.message}")
  end

  # Set restaurant from nested route parameter
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_ordrparticipant
    @ordrparticipant = Ordrparticipant.find(params[:id])
    if current_user && (@ordrparticipant.nil? || (@ordrparticipant.ordr.restaurant.user != current_user))
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Set ordrparticipant for direct updates (unauthenticated smart menu interface)
  def set_ordrparticipant_for_direct_update
    @ordrparticipant = Ordrparticipant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Ordrparticipant not found' }, status: :not_found
  end

  # Only allow a list of trusted parameters through.
  def ordrparticipant_params
    # Remove dangerous mass assignment parameters (employee_id, ordr_id, ordritem_id, role)
    # These should be set explicitly in controller actions, not via mass assignment
    params.require(:ordrparticipant).permit(:sessionid, :action, :name,
                                            :preferredlocale, allergyn_ids: [],)
  end
end
