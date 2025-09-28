module Api
  module V1
    class OcrMenuItemSerializer
      def initialize(item)
        @item = item
      end

      def as_json
        {
          id: @item.id,
          name: @item.name,
          description: @item.description,
          price: @item.price&.to_f,
          allergens: @item.allergens || [],
          dietary_restrictions: {
            is_vegetarian: @item.try(:is_vegetarian) || false,
            is_vegan: @item.try(:is_vegan) || false,
            is_gluten_free: @item.try(:is_gluten_free) || false,
            is_dairy_free: @item.try(:is_dairy_free) || false,
            is_nut_free: @item.try(:is_nut_free) || false,
          },
          sequence: @item.sequence,
          is_confirmed: @item.is_confirmed,
          created_at: @item.created_at&.iso8601,
          updated_at: @item.updated_at&.iso8601,
        }
      end

      def self.collection(items)
        items.map { |item| new(item).as_json }
      end
    end
  end
end
