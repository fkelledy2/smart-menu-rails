# frozen_string_literal: true

module Agents
  module Tools
    # Fetches raw menu source content from an OcrMenuImport record.
    # Aggregates existing OCR-extracted sections and items into structured text.
    # Low-risk read-only tool — auto-approved by default.
    class FetchMenuSource < BaseTool
      def self.tool_name
        'fetch_menu_source'
      end

      def self.description
        'Fetch the raw OCR-extracted menu text from an OcrMenuImport record, including sections and items.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            ocr_menu_import_id: {
              type: 'integer',
              description: 'The ID of the OcrMenuImport record to fetch source from',
            },
          },
          required: ['ocr_menu_import_id'],
        }
      end

      def self.call(params)
        import_id = params['ocr_menu_import_id'] || params[:ocr_menu_import_id]
        import = OcrMenuImport.includes(ocr_menu_sections: :ocr_menu_items).find(import_id)

        sections_data = import.ocr_menu_sections.order(sequence: :asc).map do |section|
          {
            name: section.name,
            items: section.ocr_menu_items.ordered.map do |item|
              {
                name: item.name,
                description: item.description,
                price: item.price,
                allergens: item.allergens,
                is_vegetarian: item.is_vegetarian,
                is_vegan: item.is_vegan,
                is_gluten_free: item.is_gluten_free,
              }
            end,
          }
        end

        {
          ocr_menu_import_id: import.id,
          name: import.name,
          source_locale: import.source_locale,
          sections_count: sections_data.size,
          items_count: sections_data.sum { |s| s[:items].size },
          sections: sections_data,
        }
      end
    end
  end
end
