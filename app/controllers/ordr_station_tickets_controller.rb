class OrdrStationTicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_ticket

  def update
    new_status = ticket_params[:status]

    ActiveRecord::Base.transaction do
      @ticket.update!(status: new_status)

      # Update item statuses within the ticket to match station progress.
      # This keeps the customer view consistent while allowing multiple tickets per order.
      if new_status == 'preparing'
        @ticket.ordritems.update_all(status: 22)
      elsif new_status == 'ready'
        @ticket.ordritems.update_all(status: 24)
      elsif new_status == 'collected'
        @ticket.ordritems.update_all(status: 25)
      end
    end

    respond_to do |format|
      format.json { render json: { status: 'ok' } }
      format.html { redirect_back fallback_location: restaurant_kitchen_dashboard_path(@restaurant) }
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
    unless @restaurant && (@restaurant.user == current_user || current_user.admin?)
      redirect_to root_path, alert: 'Access denied'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Restaurant not found'
  end

  def set_ticket
    @ticket = OrdrStationTicket.find(params[:id])
    unless @ticket.restaurant_id == @restaurant.id
      redirect_to root_path, alert: 'Access denied'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Ticket not found'
  end

  def ticket_params
    params.require(:ordr_station_ticket).permit(:status)
  end
end
