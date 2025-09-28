module Api
  module V1
    class OcrMenuSectionSerializer
      def initialize(section, include_items: false)
        @section = section
        @include_items = include_items
      end

      def as_json
        result = {
          id: @section.id,
          name: @section.name,
          description: @section.try(:description),
          sequence: @section.sequence,
          is_confirmed: @section.is_confirmed,
          page_reference: @section.page_reference,
          created_at: @section.created_at&.iso8601,
          updated_at: @section.updated_at&.iso8601
        }

        if @include_items
          result[:items] = OcrMenuItemSerializer.collection(@section.ocr_menu_items.ordered)
        end

        result
      end

      def self.collection(sections, include_items: false)
        sections.map { |section| new(section, include_items: include_items).as_json }
      end
    end
  end
end
