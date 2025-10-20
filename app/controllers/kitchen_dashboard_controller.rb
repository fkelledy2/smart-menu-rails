class KitchenDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  
  def index
    # Get orders by kitchen workflow status
    @pending_orders = @restaurant.ordrs
                                 .where(status: 'ordered')
                                 .includes(ordritems: [:menuitem, :ordritemnotes], tablesetting: [])
                                 .order(created_at: :asc)
    
    @preparing_orders = @restaurant.ordrs
                                   .where(status: 'preparing')
                                   .includes(ordritems: [:menuitem, :ordritemnotes], tablesetting: [])
                                   .order(created_at: :asc)
    
    @ready_orders = @restaurant.ordrs
                               .where(status: 'ready')
                               .includes(ordritems: [:menuitem, :ordritemnotes], tablesetting: [])
                               .order(updated_at: :desc)
    
    # Kitchen metrics
    @metrics = {
      total_pending: @pending_orders.count,
      total_preparing: @preparing_orders.count,
      total_ready: @ready_orders.count,
      avg_prep_time: calculate_avg_prep_time,
      orders_today: @restaurant.ordrs.where('created_at >= ?', Time.current.beginning_of_day).count
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
  
  def calculate_avg_prep_time
    completed_today = @restaurant.ordrs
                                 .where('created_at >= ?', Time.current.beginning_of_day)
                                 .where(status: ['ready', 'delivered', 'paid'])
    
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
