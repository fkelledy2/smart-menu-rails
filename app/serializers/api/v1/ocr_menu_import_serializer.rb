module Api
  module V1
    class OcrMenuImportSerializer
      def initialize(import, include_sections: false, include_items: false)
        @import = import
        @include_sections = include_sections
        @include_items = include_items
      end

      def as_json
        result = {
          id: @import.id,
          name: @import.name,
          status: @import.status,
          total_pages: @import.total_pages,
          processed_pages: @import.processed_pages,
          error_message: @import.error_message,
          completed_at: @import.completed_at&.iso8601,
          failed_at: @import.failed_at&.iso8601,
          created_at: @import.created_at&.iso8601,
          updated_at: @import.updated_at&.iso8601,
          restaurant_id: @import.restaurant_id,
          menu_id: @import.menu_id
        }

        if @include_sections
          result[:sections] = OcrMenuSectionSerializer.collection(
            @import.ocr_menu_sections.ordered, 
            include_items: @include_items
          )
        end

        result
      end

      def self.collection(imports, include_sections: false, include_items: false)
        imports.map { |import| new(import, include_sections: include_sections, include_items: include_items).as_json }
      end
    end
  end
end
