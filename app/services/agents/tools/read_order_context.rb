# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::ReadOrderContext reads a full Ordr record with all associated
    # Ordritem, Ordrparticipant, and OrdrAction records plus table and server context.
    # Returns a structured hash safe for LLM input.
    class ReadOrderContext < BaseTool
      def self.tool_name
        'read_order_context'
      end

      def self.description
        'Read the full context for an order including items ordered, table, server, timing, and any rating/review text.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            ordr_id: {
              type: 'integer',
              description: 'The ID of the Ordr record to read.',
            },
            restaurant_id: {
              type: 'integer',
              description: 'The restaurant the order belongs to (for scoping).',
            },
          },
          required: %w[ordr_id restaurant_id],
        }
      end

      def self.call(params)
        ordr_id       = params['ordr_id'].to_i
        restaurant_id = params['restaurant_id'].to_i

        ordr = Ordr
          .where(restaurant_id: restaurant_id)
          .includes(:tablesetting, :employee, ordritems: :menuitem, ordrparticipants: [], ordractions: [])
          .find_by(id: ordr_id)

        return { error: "Order #{ordr_id} not found" } unless ordr

        items = ordr.ordritems.reject { |i| i.status.to_s == 'removed' }.map do |oi|
          {
            'id' => oi.id,
            'name' => oi.menuitem&.name || 'Item',
            'quantity' => oi.quantity,
            'status' => oi.status.to_s,
          }
        end

        customer_participant = ordr.ordrparticipants.find { |p| p.role.to_s == 'customer' }

        {
          'ordr_id' => ordr.id,
          'table_name' => ordr.tablesetting&.name || "Order ##{ordr.id}",
          'server_name' => ordr.employee&.name,
          'status' => ordr.status.to_s,
          'gross' => ordr.gross,
          'nett' => ordr.nett,
          'tip' => ordr.tip,
          'items' => items,
          'item_count' => items.size,
          'customer_name' => customer_participant&.name,
          'created_at' => ordr.created_at.iso8601,
          'updated_at' => ordr.updated_at.iso8601,
          'bill_requested_at' => ordr.billRequestedAt&.iso8601,
          'paid_at' => ordr.paidAt&.iso8601,
        }
      end
    end
  end
end
