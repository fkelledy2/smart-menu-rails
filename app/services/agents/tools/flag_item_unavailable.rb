# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::FlagItemUnavailable — sets a Menuitem as hidden (86'd).
    #
    # SAFETY CONTRACT: This tool MUST NOT be called without a confirmed AgentApproval
    # of type `item_86`. If called without a valid approved approval, it raises
    # Agents::UnauthorisedActionError and logs the attempt.
    #
    # The `hidden: true` field is the platform convention for 86'ing an item —
    # it removes the item from the live SmartMenu immediately.
    #
    # Params:
    #   menuitem_id  [Integer] — the Menuitem to hide
    #   approval_id  [Integer] — the AgentApproval.id with status 'approved'
    class FlagItemUnavailable < BaseTool
      def self.tool_name
        'flag_item_unavailable'
      end

      def self.description
        'Marks a menu item as hidden (86\'d) after staff confirmation. Requires an approved AgentApproval.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            menuitem_id: { type: 'integer', description: 'The ID of the Menuitem to hide' },
            approval_id: { type: 'integer', description: 'The AgentApproval ID with status approved' },
          },
          required: %w[menuitem_id approval_id],
        }
      end

      # @param params [Hash] { 'menuitem_id' => Integer, 'approval_id' => Integer }
      # @return [Hash] result with :success and :menuitem_id
      # @raise [Agents::UnauthorisedActionError] if no valid approved approval exists
      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @menuitem_id = params['menuitem_id']&.to_i
        @approval_id = params['approval_id']&.to_i
      end

      def call
        validate_approval!

        menuitem = Menuitem.find_by(id: @menuitem_id)
        unless menuitem
          return { success: false, error: "Menuitem #{@menuitem_id} not found", menuitem_id: @menuitem_id }
        end

        menuitem.update!(hidden: true)
        menuitem.expire_cache if menuitem.respond_to?(:expire_cache)

        Rails.logger.info(
          "[FlagItemUnavailable] Menuitem #{@menuitem_id} (#{menuitem.name}) hidden by approval #{@approval_id}",
        )

        {
          success: true,
          menuitem_id: @menuitem_id,
          item_name: menuitem.name,
          hidden: true,
        }
      end

      private

      def validate_approval!
        unless @approval_id.present? && @menuitem_id.present?
          log_unauthorised_attempt!
          raise Agents::UnauthorisedActionError,
                'flag_item_unavailable requires both menuitem_id and approval_id'
        end

        approval = AgentApproval.find_by(id: @approval_id, action_type: 'item_86')

        unless approval&.approved?
          log_unauthorised_attempt!
          raise Agents::UnauthorisedActionError,
                "flag_item_unavailable requires an approved AgentApproval (got: #{approval&.status || 'not found'})"
        end

        # Confirm the approval is for this menuitem
        proposed = approval.proposed_payload || {}
        return unless proposed['menuitem_id'].present? && proposed['menuitem_id'].to_i != @menuitem_id

        log_unauthorised_attempt!
        raise Agents::UnauthorisedActionError,
              "AgentApproval #{@approval_id} is for menuitem #{proposed['menuitem_id']}, not #{@menuitem_id}"
      end

      def log_unauthorised_attempt!
        Rails.logger.warn(
          "[FlagItemUnavailable] UNAUTHORISED attempt — menuitem_id=#{@menuitem_id} approval_id=#{@approval_id}",
        )
      end
    end
  end
end
