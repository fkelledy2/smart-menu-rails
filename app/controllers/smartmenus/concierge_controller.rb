# frozen_string_literal: true

module Smartmenus
  # Smartmenus::ConciergeController
  #
  # Handles natural-language queries from the customer concierge panel.
  # This is a public, unauthenticated endpoint — the customer need not be
  # signed in. Rate limiting is enforced via Rack::Attack per session.
  #
  # Route: POST /t/:public_token/concierge/query
  #
  # Feature flag: agent_customer_concierge (per-restaurant)
  # Master flag:  agent_framework
  class ConciergeController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false
    skip_around_action :switch_locale, raise: false
    skip_forgery_protection

    before_action :set_smartmenu
    before_action :require_feature_flags!
    before_action :validate_query_params!

    MAX_HISTORY_TURNS  = 5
    MAX_QUERY_LENGTH   = 500

    # POST /t/:public_token/concierge/query
    def query
      conversation_history = parse_conversation_history

      result = Agents::CustomerConciergeService.call(
        restaurant:           @restaurant,
        smartmenu:            @smartmenu,
        query_text:           params[:query_text].to_s.strip,
        conversation_history: conversation_history,
        sessionid:            session[:dining_session_token],
        workflow_run_id:      params[:workflow_run_id],
      )

      if result.error.present?
        render json: { error: result.error, items: [], basket: nil }, status: :unprocessable_entity
      else
        render json: {
          items:           result.items,
          basket:          result.basket,
          workflow_run_id: result.workflow_run_id,
        }
      end
    rescue StandardError => e
      Rails.logger.error("[Smartmenus::ConciergeController#query] #{e.class}: #{e.message}")
      render json: {
        error: I18n.t('smartmenus.concierge.error_unavailable',
                      default: 'Recommendations unavailable right now — browse the menu below'),
        items: [],
        basket: nil,
      }, status: :service_unavailable
    end

    private

    def set_smartmenu
      @smartmenu  = Smartmenu.find_by!(public_token: params[:public_token])
      @restaurant = @smartmenu.menu&.restaurant || @smartmenu.restaurant
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Menu not found' }, status: :not_found
    end

    def require_feature_flags!
      return if Flipper.enabled?(:agent_framework) &&
                Flipper.enabled?(:agent_customer_concierge, @restaurant)

      render json: {
        error: I18n.t('smartmenus.concierge.feature_disabled',
                      default: 'Concierge is not available for this menu'),
      }, status: :forbidden
    end

    def validate_query_params!
      text = params[:query_text].to_s.strip

      if text.blank?
        render json: { error: 'query_text is required' }, status: :bad_request
        return
      end

      if text.length > MAX_QUERY_LENGTH
        render json: { error: "query_text must be #{MAX_QUERY_LENGTH} characters or fewer" }, status: :bad_request
      end
    end

    def parse_conversation_history
      raw = params[:conversation_history]
      return [] unless raw.is_a?(Array)

      raw.last(MAX_HISTORY_TURNS).filter_map do |turn|
        role    = turn[:role]    || turn['role']
        content = turn[:content] || turn['content']
        next unless %w[user assistant].include?(role.to_s) && content.to_s.strip.present?

        { 'role' => role.to_s, 'content' => content.to_s.first(2000) }
      end
    end
  end
end
