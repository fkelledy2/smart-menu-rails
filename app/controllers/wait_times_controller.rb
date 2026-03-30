# frozen_string_literal: true

# Staff-facing wait time dashboard and queue management controller.
# All actions are scoped to a single restaurant (params[:id]).
# Gated by the `wait_time_estimation` Flipper flag.
class WaitTimesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :check_feature_flag

  # GET /restaurants/:id/wait_times
  def show
    authorize @restaurant, policy_class: WaitTimePolicy

    service = WaitTime::EstimationService.new(@restaurant)
    @estimates = service.estimates_for_standard_sizes
    @using_default_estimates = service.using_default_estimates?
    @queue = @restaurant.customer_wait_queues.active.by_position.includes(:tablesetting)
    @tablesettings = @restaurant.tablesettings.where(archived: false).order(:sequence, :id)
    @new_entry = CustomerWaitQueue.new
  end

  # POST /restaurants/:id/wait_times/queue
  def create_queue_entry
    authorize @restaurant, policy_class: WaitTimePolicy

    result = WaitTime::QueueManager.new(@restaurant).enqueue(
      customer_name: queue_params[:customer_name],
      party_size: queue_params[:party_size].to_i,
      customer_phone: queue_params[:customer_phone],
    )

    if result.success?
      redirect_to wait_times_restaurant_path(@restaurant),
                  notice: "#{result.record.customer_name} added to queue (position ##{result.record.queue_position})"
    else
      service = WaitTime::EstimationService.new(@restaurant)
      @estimates = service.estimates_for_standard_sizes
      @using_default_estimates = service.using_default_estimates?
      @queue = @restaurant.customer_wait_queues.active.by_position.includes(:tablesetting)
      @tablesettings = @restaurant.tablesettings.where(archived: false).order(:sequence, :id)
      @new_entry = result.record
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_content
    end
  end

  # PATCH /restaurants/:id/wait_times/queue/:entry_id/seat
  def seat_queue_entry
    entry = find_queue_entry
    return unless entry

    authorize @restaurant, policy_class: WaitTimePolicy

    tablesetting = if params[:tablesetting_id].present?
                     @restaurant.tablesettings.find_by(id: params[:tablesetting_id])
                   else
                     nil
                   end

    result = WaitTime::QueueManager.new(@restaurant).seat(entry, tablesetting: tablesetting)

    respond_to do |format|
      if result.success?
        format.html { redirect_to wait_times_restaurant_path(@restaurant), notice: "#{entry.customer_name} has been seated." }
        format.turbo_stream { render_queue_stream }
      else
        format.html { redirect_to wait_times_restaurant_path(@restaurant), alert: result.error }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('wait_queue_flash', partial: 'wait_times/flash', locals: { message: result.error, type: 'danger' }) }
      end
    end
  end

  # PATCH /restaurants/:id/wait_times/queue/:entry_id/no_show
  def no_show_queue_entry
    entry = find_queue_entry
    return unless entry

    authorize @restaurant, policy_class: WaitTimePolicy

    result = WaitTime::QueueManager.new(@restaurant).mark_no_show(entry)

    respond_to do |format|
      if result.success?
        format.html { redirect_to wait_times_restaurant_path(@restaurant), notice: "#{entry.customer_name} marked as no-show." }
        format.turbo_stream { render_queue_stream }
      else
        format.html { redirect_to wait_times_restaurant_path(@restaurant), alert: result.error }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('wait_queue_flash', partial: 'wait_times/flash', locals: { message: result.error, type: 'danger' }) }
      end
    end
  end

  # PATCH /restaurants/:id/wait_times/queue/:entry_id/cancel
  def cancel_queue_entry
    entry = find_queue_entry
    return unless entry

    authorize @restaurant, policy_class: WaitTimePolicy

    result = WaitTime::QueueManager.new(@restaurant).cancel(entry)

    respond_to do |format|
      if result.success?
        format.html { redirect_to wait_times_restaurant_path(@restaurant), notice: "#{entry.customer_name} removed from queue." }
        format.turbo_stream { render_queue_stream }
      else
        format.html { redirect_to wait_times_restaurant_path(@restaurant), alert: result.error }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('wait_queue_flash', partial: 'wait_times/flash', locals: { message: result.error, type: 'danger' }) }
      end
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: 'Restaurant not found.' }
      format.json { head :not_found }
    end
  end

  def check_feature_flag
    return if Flipper.enabled?(:wait_time_estimation, @restaurant)

    respond_to do |format|
      format.html { redirect_to restaurant_path(@restaurant), alert: 'Wait time estimation is not enabled for this restaurant.' }
      format.json { render json: { error: 'Feature not enabled' }, status: :service_unavailable }
    end
  end

  def find_queue_entry
    @restaurant.customer_wait_queues.find(params[:entry_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to wait_times_restaurant_path(@restaurant), alert: 'Queue entry not found.' }
      format.turbo_stream { head :not_found }
    end
    nil
  end

  def queue_params
    params.require(:customer_wait_queue).permit(:customer_name, :party_size, :customer_phone)
  end

  def render_queue_stream
    queue = @restaurant.customer_wait_queues.active.by_position.includes(:tablesetting)
    service = WaitTime::EstimationService.new(@restaurant)
    estimates = service.estimates_for_standard_sizes
    using_default_estimates = service.using_default_estimates?
    tablesettings = @restaurant.tablesettings.where(archived: false).order(:sequence, :id)

    render turbo_stream: [
      turbo_stream.replace('wait_queue_list', partial: 'wait_times/queue_list',
                                              locals: { queue: queue, restaurant: @restaurant, tablesettings: tablesettings },),
      turbo_stream.replace('wait_time_estimates', partial: 'wait_times/estimates',
                                                  locals: { estimates: estimates, using_default_estimates: using_default_estimates },),
    ]
  end
end
