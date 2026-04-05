# frozen_string_literal: true

module Restaurants
  # Staff Copilot — natural-language back-office assistant.
  #
  # POST /restaurants/:id/copilot/query   — submit a query, receive response
  # POST /restaurants/:id/copilot/confirm — execute a confirmed write action
  #
  # Both endpoints render Turbo Stream responses that update the copilot panel
  # in the back-office layout without a full page reload.
  class CopilotController < BaseController
    before_action :set_restaurant
    before_action :check_feature_flags

    # POST /restaurants/:id/copilot/query
    def query
      authorize @restaurant, :query?, policy_class: CopilotPolicy

      query_text           = params[:query_text].to_s.strip
      conversation_history = parse_conversation_history
      page_context         = params[:page_context].to_s

      result = Agents::StaffCopilotService.call(
        restaurant: @restaurant,
        user: current_user,
        query_text: query_text,
        conversation_history: conversation_history,
        page_context: page_context,
      )

      @response = result

      respond_to do |format|
        format.turbo_stream
        format.json { render json: serialise_response(result) }
      end
    end

    # POST /restaurants/:id/copilot/confirm
    def confirm
      authorize @restaurant, :confirm?, policy_class: CopilotPolicy

      tool_name      = params[:tool_name].to_s
      confirm_params = parse_confirm_params

      # Guard: reject unregistered tools immediately before entering the service
      unless Agents::StaffCopilotConfirmService::ALLOWED_TOOLS.include?(tool_name)
        respond_to do |format|
          format.turbo_stream { render_confirm_error('Unknown or disallowed action.') }
          format.json { render json: { success: false, message: 'Unknown or disallowed action.' }, status: :unprocessable_content }
        end
        return
      end

      result = Agents::StaffCopilotConfirmService.call(
        restaurant: @restaurant,
        user: current_user,
        tool_name: tool_name,
        confirm_params: confirm_params,
      )

      @confirm_result = result

      respond_to do |format|
        format.turbo_stream
        format.json { render json: { success: result.success?, message: result.message } }
      end
    end

    private

    def check_feature_flags
      unless Flipper.enabled?(:agent_framework, @restaurant) &&
             Flipper.enabled?(:agent_staff_copilot, @restaurant)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'copilot-response',
              partial: 'restaurants/copilot/feature_disabled',
            )
          end
          format.json { render json: { error: 'Feature not available.' }, status: :not_found }
          format.html { redirect_to restaurant_path(@restaurant), alert: 'Staff Copilot is not enabled for this restaurant.' }
        end
      end
    end

    def parse_conversation_history
      raw = params[:conversation_history]
      return [] if raw.blank?

      case raw
      when String
        JSON.parse(raw).last(5)
      when Array
        raw.last(5)
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def parse_confirm_params
      permitted = params.permit(
        :tool_name,
        :menuitem_id,
        :hide,
        :name,
        :price_cents,
        :description,
        :menusection_id,
        :subject,
        :body,
        allergen_names: [],
      ).to_h.except('tool_name')

      permitted.transform_values { |v| v.is_a?(String) && v == '' ? nil : v }
    end

    def render_confirm_error(message)
      render turbo_stream: turbo_stream.replace(
        'copilot-confirm-result',
        partial: 'restaurants/copilot/confirm_error',
        locals: { message: message },
      )
    end

    def serialise_response(result)
      {
        response_type: result.response_type,
        narrative_text: result.narrative_text,
        action_card: result.action_card,
        disambiguation: result.disambiguation,
        intent_type: result.intent_type,
        tool_called: result.tool_called,
      }
    end
  end
end
