# frozen_string_literal: true

module Agents
  module Tools
    # Builds a suggested complete basket for a group given a list of available
    # items, group size, and optional budget constraint.
    # Pure Ruby / arithmetic — no LLM call inside this tool.
    class ProposeBasket < BaseTool
      MAX_ITEMS_IN_BASKET = 20

      def self.tool_name
        'propose_basket'
      end

      def self.description
        'Build a suggested basket of menu items for a group given group size and optional budget.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            item_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'Candidate menu item IDs to select from',
            },
            group_size: { type: 'integer', description: 'Number of people ordering', default: 2 },
            budget: { type: 'number', description: 'Maximum total budget in base currency units. Omit for no limit.' },
          },
          required: ['item_ids'],
        }
      end

      def self.call(params)
        item_ids   = Array(params['item_ids'] || params[:item_ids]).map(&:to_i)
        group_size = [(params['group_size'] || params[:group_size]).to_i, 1].max
        budget     = (params['budget'] || params[:budget])&.to_f

        items = Menuitem.where(id: item_ids).order(:price)
        return { items: [], total: 0, note: 'No items found' } if items.empty?

        # Simple greedy selection: pick up to (group_size * 2) items staying within budget.
        target_count = [(group_size * 2), MAX_ITEMS_IN_BASKET].min
        selected     = []
        running_total = 0.0

        items.each do |item|
          break if selected.size >= target_count

          price = item.price.to_f
          if budget.nil? || (running_total + price) <= budget
            selected << item
            running_total += price
          end
        end

        {
          items: selected.map { |i| { id: i.id, name: i.name, price: i.price } },
          total: running_total.round(2),
          item_count: selected.size,
          group_size: group_size,
        }
      end
    end
  end
end
