# frozen_string_literal: true

module Agents
  module Tools
    # Reads top-level restaurant context: name, address, currency, menu count, section/item counts.
    # Low-risk read-only tool — auto-approved by default.
    class ReadRestaurantContext < BaseTool
      def self.tool_name
        'read_restaurant_context'
      end

      def self.description
        'Read the restaurant name, address, currency, menu structure, and basic settings.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            restaurant_id: { type: 'integer', description: 'The restaurant ID' },
          },
          required: ['restaurant_id'],
        }
      end

      def self.call(params)
        restaurant = Restaurant.find(params['restaurant_id'] || params[:restaurant_id])

        menus = restaurant.menus.where(archived: false).includes(:menu_sections)

        {
          id: restaurant.id,
          name: restaurant.name,
          currency: restaurant.currency,
          country: restaurant.country,
          menus: menus.map do |menu|
            {
              id: menu.id,
              name: menu.name,
              status: menu.status,
              section_count: menu.menu_sections.size,
            }
          end,
        }
      end
    end
  end
end
