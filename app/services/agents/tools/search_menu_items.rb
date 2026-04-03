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
            exclude_allergyn_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'Allergyn IDs whose items must be excluded from results. Applied in SQL before LLM sees items.',
            },
            limit: { type: 'integer', default: 20 },
          },
          required: ['restaurant_id'],
        }
      end

      def self.call(params)
        restaurant_id = params['restaurant_id'] || params[:restaurant_id]

        scope = Menuitem
          .joins(menusection: :menu)
          .where(menus: { restaurant_id: restaurant_id, archived: false })

        if (q = params['query'].presence)
          scope = scope.where('menuitems.name ILIKE ?', "%#{q}%")
        end

        if (section_id = params['section_id'])
          scope = scope.where(menusection_id: section_id)
        end

        if (min_price = params['min_price'])
          scope = scope.where(menuitems: { price: min_price.. })
        end

        if (max_price = params['max_price'])
          scope = scope.where(menuitems: { price: ..max_price })
        end

        # Allergen exclusion — enforced at SQL level, never delegated to the LLM.
        exclude_ids = Array(params['exclude_allergyn_ids'] || params[:exclude_allergyn_ids]).map(&:to_i).select(&:positive?)
        if exclude_ids.any?
          items_with_excluded_allergens = MenuitemAllergynMapping
            .where(allergyn_id: exclude_ids)
            .select(:menuitem_id)
          scope = scope.where.not(id: items_with_excluded_allergens)
        end

        limit = [params.fetch('limit', 20).to_i, 100].min

        items = scope.order('menuitems.name ASC').limit(limit)

        {
          total: scope.count,
          items: items.map do |item|
            {
              id: item.id,
              name: item.name,
              price: item.price,
              section_id: item.menusection_id,
            }
          end,
        }
      end
    end
  end
end
