# frozen_string_literal: true

module Restaurants
  class AlcoholPolicyController < BaseController
    before_action :set_restaurant

    # PATCH /restaurants/:id/update_alcohol_policy
    def update_alcohol_policy
      authorize @restaurant

      payload = params.permit(
        allowed_days_of_week: [],
        allowed_time_ranges: %i[from_min to_min],
        blackout_dates: [],
      )

      policy = @restaurant.alcohol_policy || @restaurant.build_alcohol_policy

      days = Array(payload[:allowed_days_of_week]).map(&:to_i).uniq.sort
      ranges = Array(payload[:allowed_time_ranges]).map do |r|
        h = r.is_a?(ActionController::Parameters) ? r.to_unsafe_h : r
        { 'from_min' => h['from_min'].to_i, 'to_min' => h['to_min'].to_i }
      end
      dates = Array(payload[:blackout_dates]).filter_map do |d|
        Date.parse(d)
      rescue StandardError => e
        Rails.logger.warn("[Restaurants::AlcoholPolicyController] Failed to parse blackout date: #{e.message}")
        nil
      end.uniq.sort

      policy.allowed_days_of_week = days
      policy.allowed_time_ranges = ranges
      policy.blackout_dates = dates

      if policy.save
        AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)
        render json: { success: true, allowed_now: @restaurant.alcohol_allowed_now? }, status: :ok
      else
        render json: { success: false, errors: policy.errors.full_messages }, status: :unprocessable_content
      end
    end

    # GET /restaurants/:id/alcohol_status
    def alcohol_status
      authorize @restaurant
      render json: { allowed_now: @restaurant.alcohol_allowed_now? }
    end
  end
end
