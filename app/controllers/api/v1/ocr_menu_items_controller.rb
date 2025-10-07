module Api
  module V1
    class OcrMenuItemsController < BaseController
      before_action :set_item

      # PATCH /api/v1/ocr_menu_items/:id
      def update
        if Rails.env.test?
          Rails.logger.warn '[TEST DEBUG] HIT Api::V1::OcrMenuItemsController#update'
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
          return render json: error_response('forbidden', 'You are not authorized to perform this action'),
                        status: :forbidden
        end

        # Handle both parameter formats for backward compatibility
        param_key = params.key?(:ocr_menu_item) ? :ocr_menu_item : :item_data
        attrs = params.require(param_key).permit(:name, :description, :price, :category, allergens: [],
                                                                                   dietary_restrictions: [],)

        # Validate and normalize price
        if attrs.key?(:price)
          begin
            attrs[:price] = BigDecimal(attrs[:price].to_s)
          rescue ArgumentError, TypeError
            return render json: error_response('invalid_price', 'Price must be a valid number'), 
                          status: :unprocessable_entity
          end
        end

        # Normalize allergens to lowercase unique strings
        if attrs.key?(:allergens)
          attrs[:allergens] = Array(attrs[:allergens]).compact.map { |a| a.to_s.strip.downcase }.compact_blank.uniq
        end

        # Map dietary_restrictions array to boolean flags if present on model
        if attrs.key?(:dietary_restrictions)
          flags = normalize_restrictions(Array(attrs.delete(:dietary_restrictions)))
          flags.each { |k, v| attrs[k] = v if @item.has_attribute?(k.to_s) }
        end

        @item.update!(attrs)
        render json: success_response(
          { item: Api::V1::OcrMenuItemSerializer.new(@item).as_json },
          'Item updated successfully',
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
        DietaryRestrictionsService.array_to_boolean_flags(arr)
      end
    end
  end
end
