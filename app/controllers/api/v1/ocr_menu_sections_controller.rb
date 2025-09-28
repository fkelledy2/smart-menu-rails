module Api
  module V1
    class OcrMenuSectionsController < BaseController
      before_action :set_section

      # PATCH /api/v1/ocr_menu_sections/:id
      def update
        authorize @section

        # Test-only diagnostics for authorization debugging
        if Rails.env.test?
          import = @section.ocr_menu_import
          restaurant = import&.restaurant
          owner_id = restaurant&.user_id
          current_id = current_user&.id
          is_owner = owns_section?(current_user, @section)
          Rails.logger.warn "[TEST DEBUG] OcrMenuSectionsController#update: current_user.id=#{current_id}, owner_id=#{owner_id}, is_owner=#{is_owner}"
        end

        unless owns_section?(current_user, @section)
          return render json: error_response('forbidden', 'You are not authorized to perform this action'),
                        status: :forbidden
        end

        attrs = params.require(:ocr_menu_section).permit(:name, :description)
        @section.update!(attrs)
        render json: success_response(
          { section: Api::V1::OcrMenuSectionSerializer.new(@section).as_json },
          'Section updated successfully',
        )
      end

      private

      def set_section
        @section = OcrMenuSection.find(params[:id])
      end

      def owns_section?(user, section)
        return false unless user && section

        import = section.ocr_menu_import
        restaurant = import&.restaurant
        restaurant && restaurant.user_id == user.id
      end
    end
  end
end
