# frozen_string_literal: true

module Agents
  module Tools
    # Reads the current customer's dietary flags (allergen exclusions) and
    # preferred locale from the Menuparticipant and Ordrparticipant records.
    # Used by CustomerConciergeService to inject dietary context before any
    # LLM call — allergen enforcement happens at the tool level, not by the LLM.
    class ReadCustomerPreferences < BaseTool
      def self.tool_name
        'read_customer_preferences'
      end

      def self.description
        'Read the current customer\'s allergen exclusions and locale from their session.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            smartmenu_id: { type: 'integer', description: 'Smartmenu the customer is viewing' },
            sessionid: { type: 'string', description: 'Session identifier for the customer' },
          },
          required: %w[smartmenu_id],
        }
      end

      def self.call(params)
        smartmenu_id = params['smartmenu_id'] || params[:smartmenu_id]
        sessionid    = params['sessionid']    || params[:sessionid]

        participant = if sessionid.present?
          Menuparticipant.find_by(smartmenu_id: smartmenu_id, sessionid: sessionid)
        end

        # Allergen exclusions come from OrdrparticipantAllergynFilters linked to
        # the ordrparticipant for this session (the more precise source).
        allergen_ids = []
        if sessionid.present?
          ordrparticipant = Ordrparticipant
            .joins(:ordr)
            .where(
              sessionid: sessionid,
              ordrs: { smartmenu_id: smartmenu_id },
            )
            .order(created_at: :desc)
            .first

          if ordrparticipant
            allergen_ids = ordrparticipant
              .ordrparticipant_allergyn_filters
              .pluck(:allergyn_id)
          end
        end

        {
          locale: participant&.preferredlocale || 'en',
          excluded_allergyn_ids: allergen_ids,
          has_dietary_restrictions: allergen_ids.any?,
        }
      end
    end
  end
end
