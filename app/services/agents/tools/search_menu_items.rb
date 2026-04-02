# frozen_string_literal: true

module Agents
  module Tools
    # Searches menu items for a restaurant using optional filters.
    # Low-risk read-only tool — auto-approved by default.
    class SearchMenuItems < BaseTool
      def self.tool_name
        'search_menu_items'
      end

      def self.description
        'Search menu items for a restaurant with optional name, section, price range, or tag filters.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            restaurant_id: { type: 'integer' },
            query: { type: 'string', description: 'Name search term' },
            section_id: { type: 'integer', description: 'Filter by menu section ID' },
            min_price: { type: 'number', description: 'Minimum price in base currency units' },
            max_price: { type: 'number', description: 'Maximum price in base currency units' },
            limit: { type: 'integer', default: 20 },
          },
          required: ['restaurant_id'],
        }
      end

      def self.call(params)
        restaurant_id = params['restaurant_id'] || params[:restaurant_id]

        scope = Menuitem
          .joins(menu_section: :menu)
          .where(menus: { restaurant_id: restaurant_id, archived: false })

        if (q = params['query'].presence)
          scope = scope.where('menu_items.name ILIKE ?', "%#{q}%")
        end

        if (section_id = params['section_id'])
          scope = scope.where(menu_section_id: section_id)
        end

        if (min_price = params['min_price'])
          scope = scope.where(menu_items: { price: min_price.. })
        end

        if (max_price = params['max_price'])
          scope = scope.where(menu_items: { price: ..max_price })
        end

        limit = [params.fetch('limit', 20).to_i, 100].min

        items = scope.order('menu_items.name ASC').limit(limit)

        {
          total: scope.count,
          items: items.map do |item|
            {
              id: item.id,
              name: item.name,
              price: item.price,
              section_id: item.menu_section_id,
            }
          end,
        }
      end
    end
  end
end
