# frozen_string_literal: true

module Restaurants
  class HoursController < BaseController
    before_action :set_restaurant

    # PATCH /restaurants/:id/update_hours
    def update_hours
      authorize @restaurant

      Rails.logger.info "[UpdateHours] Received request for restaurant #{@restaurant.id}"
      Rails.logger.info "[UpdateHours] Hours params: #{params[:hours].inspect}"
      Rails.logger.info "[UpdateHours] Closed params: #{params[:closed].inspect}"

      hours_params = params[:hours] || {}

      hours_params.each do |day, times|
        Rails.logger.info "[UpdateHours] Processing day: #{day}, times: #{times.inspect}"

        availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
          dayofweek: day,
          sequence: 1,
        )

        open_time = times[:open] || times['open']
        close_time = times[:close] || times['close']

        if open_time.present? && close_time.present?
          open_parts = open_time.split(':')
          close_parts = close_time.split(':')

          availability.starthour = open_parts[0].to_i
          availability.startmin = open_parts[1].to_i
          availability.endhour = close_parts[0].to_i
          availability.endmin = close_parts[1].to_i
          availability.status = :open
        else
          Rails.logger.warn "[UpdateHours] No time data for #{day}: open=#{open_time.inspect}, close=#{close_time.inspect}"
        end

        if availability.save
          Rails.logger.info "[UpdateHours] Saved availability for #{day}: #{availability.id}"
        else
          Rails.logger.error "[UpdateHours] Failed to save availability for #{day}: #{availability.errors.full_messages}"
        end
      end

      if params[:closed].is_a?(Hash)
        params[:closed].each do |day, is_closed|
          Rails.logger.info "[UpdateHours] Processing closed day: #{day} = #{is_closed}"
          next unless is_closed == '1'

          availability = @restaurant.restaurantavailabilities.find_or_initialize_by(dayofweek: day, sequence: 1)
          availability.status = :closed
          if availability.save
            Rails.logger.info "[UpdateHours] Marked #{day} as closed"
          else
            Rails.logger.error "[UpdateHours] Failed to mark #{day} as closed: #{availability.errors.full_messages}"
          end
        end
      end

      @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)
      AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)

      respond_to do |format|
        format.json { render json: { success: true, message: 'Hours saved successfully' }, status: :ok }
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), notice: 'Hours updated successfully' }
      end
    rescue StandardError => e
      Rails.logger.error("[Restaurants::HoursController] Error updating hours: #{e.message}")
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_content }
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), alert: 'Failed to update hours' }
      end
    end
  end
end
