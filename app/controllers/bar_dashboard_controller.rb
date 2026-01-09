class BarDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @station = 'bar'

    tickets = @restaurant.ordr_station_tickets
      .where(station: :bar)
      .where.not(status: 'collected')
      .includes({ ordritems: %i[menuitem ordritemnotes] }, ordr: [:tablesetting])

    @pending_tickets = tickets.where(status: 'ordered').order(created_at: :asc)
    @preparing_tickets = tickets.where(status: 'preparing').order(created_at: :asc)
    @ready_tickets = tickets.where(status: 'ready').order(updated_at: :desc)

    @metrics = {
      total_pending: @pending_tickets.count,
      total_preparing: @preparing_tickets.count,
      total_ready: @ready_tickets.count,
    }
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
    unless @restaurant && (@restaurant.user == current_user || current_user.admin?)
      redirect_to root_path, alert: 'Access denied'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Restaurant not found'
  end
end
