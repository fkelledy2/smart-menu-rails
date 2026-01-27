require 'csv'

class RestaurantInsightsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  def show
    authorize @restaurant, :show?
    redirect_to edit_restaurant_path(@restaurant, section: 'insights')
  end

  def top_performers
    authorize @restaurant, :show?
    data = insights_service.top_performers
    respond_to do |format|
      format.json { render json: { top_performers: data } }
      format.csv do
        send_data insights_to_csv(data, %w[menuitem_id menuitem_name orders_with_item_count quantity_sold share_of_orders]),
                  filename: "top_performers_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def slow_movers
    authorize @restaurant, :show?
    data = insights_service.slow_movers
    respond_to do |format|
      format.json { render json: { slow_movers: data } }
      format.csv do
        send_data insights_to_csv(data, %w[menuitem_id menuitem_name orders_with_item_count quantity_sold share_of_orders]),
                  filename: "slow_movers_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def prep_time_bottlenecks
    authorize @restaurant, :show?
    data = insights_service.prep_time_bottlenecks
    respond_to do |format|
      format.json { render json: { prep_time_bottlenecks: data } }
      format.csv do
        send_data insights_to_csv(data, %w[menuitem_id menuitem_name median_time_to_ready_seconds sample_size is_outlier]),
                  filename: "prep_time_bottlenecks_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def voice_triggers
    authorize @restaurant, :show?
    data = insights_service.voice_triggers
    respond_to do |format|
      format.json { render json: { voice_triggers: data } }
      format.csv do
        send_data insights_to_csv(data, %w[menuitem_id menuitem_name voice_trigger_count success_count failure_count success_rate]),
                  filename: "voice_triggers_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def abandonment_funnel
    authorize @restaurant, :show?
    data = insights_service.abandonment_funnel
    respond_to do |format|
      format.json { render json: { abandonment_funnel: data } }
      format.csv do
        send_data insights_to_csv(data, %w[step_key step_count dropoff_count dropoff_rate]),
                  filename: "abandonment_funnel_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  def insights_service
    @insights_service ||= RestaurantInsightsService.new(restaurant: @restaurant, params: params)
  end

  def insights_to_csv(rows, columns)
    CSV.generate(headers: true) do |csv|
      csv << columns
      rows.each do |row|
        csv << columns.map { |k| row[k.to_sym] }
      end
    end
  end
end
