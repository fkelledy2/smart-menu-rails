module Api
  module V1
    class OcrMenuSectionsController < BaseController
      before_action :set_section

      # PATCH /api/v1/ocr_menu_sections/:id
      def update
        authorize @section

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
    end
  end
end
