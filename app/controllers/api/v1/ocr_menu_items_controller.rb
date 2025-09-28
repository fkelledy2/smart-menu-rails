module Api
  module V1
    class OcrMenuItemsController < BaseController
      before_action :set_item

      # PATCH /api/v1/ocr_menu_items/:id
      def update
        if Rails.env.test?
          Rails.logger.warn "[TEST DEBUG] HIT Api::V1::OcrMenuItemsController#update"
        end
        
        authorize @item
        
        # Test-only diagnostics for authorization debugging
        if Rails.env.test?
          section = @item.ocr_menu_section
          import = section&.ocr_menu_import
          restaurant = import&.restaurant
          owner_id = restaurant&.user_id
          current_id = current_user&.id
          is_owner = owns_item?(current_user, @item)
          Rails.logger.warn "[TEST DEBUG] Api::V1::OcrMenuItemsController#update: current_user.id=#{current_id}, owner_id=#{owner_id}, is_owner=#{is_owner}"
        end
        
        unless owns_item?(current_user, @item)
          return render json: error_response("forbidden", "You are not authorized to perform this action"), status: :forbidden
        end
        attrs = params.require(:ocr_menu_item).permit(:name, :description, :price, allergens: [], dietary_restrictions: [])

        # Normalize price
        if attrs.key?(:price)
          attrs[:price] = begin
            BigDecimal(attrs[:price].to_s)
          rescue
            0
          end
        end

        # Normalize allergens to lowercase unique strings
        if attrs.key?(:allergens)
          attrs[:allergens] = Array(attrs[:allergens]).compact.map { |a| a.to_s.strip.downcase }.reject(&:blank?).uniq
        end

        # Map dietary_restrictions array to boolean flags if present on model
        if attrs.key?(:dietary_restrictions)
          flags = normalize_restrictions(Array(attrs.delete(:dietary_restrictions)))
          flags.each { |k, v| attrs[k] = v if @item.has_attribute?(k.to_s) }
        end

        @item.update!(attrs)
        render json: success_response(
          { item: Api::V1::OcrMenuItemSerializer.new(@item).as_json },
          "Item updated successfully"
        )
      end

      private

      def set_item
        @item = OcrMenuItem.find(params[:id])
      end

      def owns_item?(user, item)
        return false unless user && item
        section = item.ocr_menu_section
        import = section&.ocr_menu_import
        restaurant = import&.restaurant
        restaurant && restaurant.user_id == user.id
      end

      def normalize_restrictions(arr)
        set = arr.map { |v| v.to_s.downcase.strip }
        {
          is_vegetarian: set.include?("vegetarian"),
          is_vegan: set.include?("vegan"),
          is_gluten_free: set.include?("gluten_free"),
          is_dairy_free: set.include?("dairy_free"),
          is_nut_free: set.include?("nut_free")
        }
      end

    end
  end
end
