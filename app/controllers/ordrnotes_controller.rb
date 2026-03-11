class OrdrnotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_order
  before_action :set_ordrnote, only: %i[show edit update destroy]

  after_action :verify_authorized
  after_action :verify_policy_scoped, only: [:index]

  def index
    authorize Ordrnote
    @ordrnotes = policy_scope(@order.ordrnotes.includes(:employee)).by_priority

    respond_to do |format|
      format.html
      format.json { render json: @ordrnotes }
    end
  end

  def show
    authorize @ordrnote
  end

  def new
    @ordrnote = @order.ordrnotes.build
    authorize @ordrnote
  end

  def edit
    authorize @ordrnote
  end

  def create
    unless current_employee
      redirect_to restaurant_ordr_path(@restaurant, @order), alert: 'You must be an employee to add notes.' and return
    end
    
    @ordrnote = @order.ordrnotes.build(ordrnote_params)
    @ordrnote.employee = current_employee
    authorize @ordrnote

    if @ordrnote.save
      broadcast_ordrnote_created
      respond_to do |format|
        format.html do
          redirect_to restaurant_ordr_path(@restaurant, @order),
                      notice: 'Order note added successfully.'
        end
        format.json { render json: @ordrnote, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @ordrnote.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @ordrnote

    if @ordrnote.update(ordrnote_params)
      broadcast_ordrnote_updated
      respond_to do |format|
        format.html do
          redirect_to restaurant_ordr_path(@restaurant, @order),
                      notice: 'Order note updated successfully.'
        end
        format.json { render json: @ordrnote }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: { errors: @ordrnote.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @ordrnote
    @ordrnote.destroy
    broadcast_ordrnote_deleted

    respond_to do |format|
      format.html do
        redirect_to restaurant_ordr_path(@restaurant, @order),
                    notice: 'Order note removed successfully.'
      end
      format.json { head :no_content }
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_order
    @order = @restaurant.ordrs.find(params[:ordr_id])
  end

  def set_ordrnote
    @ordrnote = @order.ordrnotes.find(params[:id])
  end

  def ordrnote_params
    params.require(:ordrnote).permit(:content, :category, :priority,
                                     :visible_to_kitchen, :visible_to_servers,
                                     :visible_to_customers, :expires_at,)
  end

  def current_employee
    return @current_employee if defined?(@current_employee)

    @current_employee = @restaurant.employees.find_by(user: current_user)
  end

  def broadcast_ordrnote_created
    # Broadcast to OrderChannel for real-time updates
    return unless defined?(OrderChannel)
    
    OrderChannel.broadcast_to(@order, {
      action: 'note_created',
      note_id: @ordrnote.id,
      note_html: render_note_card(@ordrnote),
    })
  rescue StandardError => e
    Rails.logger.warn("[Ordrnote] Broadcast failed: #{e.message}")
  end

  def broadcast_ordrnote_updated
    return unless defined?(OrderChannel)
    
    OrderChannel.broadcast_to(@order, {
      action: 'note_updated',
      note_id: @ordrnote.id,
      note_html: render_note_card(@ordrnote),
    })
  rescue StandardError => e
    Rails.logger.warn("[Ordrnote] Broadcast failed: #{e.message}")
  end

  def broadcast_ordrnote_deleted
    return unless defined?(OrderChannel)
    
    OrderChannel.broadcast_to(@order, {
      action: 'note_deleted',
      note_id: @ordrnote.id,
    })
  rescue StandardError => e
    Rails.logger.warn("[Ordrnote] Broadcast failed: #{e.message}")
  end

  def render_note_card(note)
    ApplicationController.render(
      partial: 'ordrnotes/note_card',
      locals: { note: note, restaurant: @restaurant, order: @order },
    )
  end
end
