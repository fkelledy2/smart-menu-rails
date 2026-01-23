class KitchenDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    @station = 'kitchen'

    tickets = @restaurant.ordr_station_tickets
      .where(station: :kitchen)
      .where.not(status: 'collected')
      .includes({ ordritems: %i[menuitem ordritemnotes] }, ordr: [:tablesetting])

    @pending_tickets = tickets.where(status: 'ordered').order(created_at: :asc)
    @preparing_tickets = tickets.where(status: 'preparing').order(created_at: :asc)
    @ready_tickets = tickets.where(status: 'ready').order(updated_at: :desc)

    @metrics = {
      total_pending: @pending_tickets.count,
      total_preparing: @preparing_tickets.count,
      total_ready: @ready_tickets.count,
      avg_prep_time: calculate_avg_prep_time,
      orders_today: @restaurant.ordrs.where(created_at: Time.current.beginning_of_day..).count,
    }
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
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

  def calculate_avg_prep_time
    completed_today = @restaurant.ordrs
      .where(created_at: Time.current.beginning_of_day..)
      .where(status: %w[ready delivered paid])

    return 0 if completed_today.empty?

    total_time = completed_today.sum do |order|
      if order.updated_at && order.created_at
        (order.updated_at - order.created_at) / 60 # in minutes
      else
        0
      end
    end

    (total_time / completed_today.count).round
  end
end
