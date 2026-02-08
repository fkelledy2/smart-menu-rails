class OrdrStationTicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_ticket

  def update
    new_status = ticket_params[:status]

    unless valid_status_value?(new_status)
      respond_to do |format|
        format.json { render json: { error: 'Invalid status' }, status: :unprocessable_content }
        format.html { redirect_back_or_to(kitchen_dashboard_restaurant_path(@restaurant), alert: 'Invalid status') }
      end
      return
    end

    unless valid_status_transition?(@ticket.status, new_status)
      respond_to do |format|
        format.json { render json: { error: 'Invalid status transition' }, status: :unprocessable_content }
        format.html { redirect_back_or_to(kitchen_dashboard_restaurant_path(@restaurant), alert: 'Invalid status transition') }
      end
      return
    end

    ActiveRecord::Base.transaction do
      @ticket.update!(status: new_status)

      # Update item statuses within the ticket to match station progress.
      # This keeps the customer view consistent while allowing multiple tickets per order.
      case new_status
      when 'preparing'
        @ticket.ordritems.update_all(status: 22)
      when 'ready'
        @ticket.ordritems.update_all(status: 24)
      when 'collected'
        @ticket.ordritems.update_all(status: 25)
      end
    end

    respond_to do |format|
      format.json { render json: { status: 'ok' } }
      format.html { redirect_back_or_to(kitchen_dashboard_restaurant_path(@restaurant)) }
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
    is_owner = @restaurant && (@restaurant.user == current_user)
    is_admin = current_user&.admin?
    is_active_employee = Employee.exists?(user_id: current_user.id, restaurant_id: @restaurant.id, status: :active)

    return if is_owner || is_admin || is_active_employee

    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Access denied' }
      format.json { head :forbidden }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Restaurant not found' }
      format.json { head :not_found }
    end
  end

  def set_ticket
    @ticket = OrdrStationTicket.find(params[:id])
    unless @ticket.restaurant_id == @restaurant.id
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'Access denied' }
        format.json { head :forbidden }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Ticket not found' }
      format.json { head :not_found }
    end
  end

  def ticket_params
    params.require(:ordr_station_ticket).permit(:status)
  end

  def valid_status_value?(value)
    OrdrStationTicket.statuses.key?(value.to_s)
  end

  def valid_status_transition?(from_status, to_status)
    from = from_status.to_s
    to = to_status.to_s

    allowed_next = {
      'ordered' => %w[preparing],
      'preparing' => %w[ready],
      'ready' => %w[collected],
      'collected' => [],
    }

    allowed_next.fetch(from, []).include?(to)
  end
end
