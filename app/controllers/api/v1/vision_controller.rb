# frozen_string_literal: true

module Api
  module V1
    class VisionController < BaseController
      include GoogleVisionAnalyzable

      # POST /api/v1/vision/analyze
      # Analyzes an uploaded image using Google Vision API
      #
      # Parameters:
      #   - image: The image file to analyze (required)
      #   - features: Comma-separated list of features to detect (optional, default: labels,text)
      #     Available features: labels, text, web, objects, landmarks
      #
      # Example request:
      #   POST /api/v1/vision/analyze
      #   Headers: Content-Type: multipart/form-data
      #   Body: { image: [binary image data] }
      #
      # Example response:
      #   {
      #     "labels": [{"description": "Food", "score": 0.98}, ...],
      #     "text": "Menu Item 1\n$12.99\n...",
      #     "web": { ... },
      #     "objects": [{"name": "Pizza", "score": 0.95, ...}],
      #     "landmarks": [...]
      #   }
      def analyze
        unless params[:image].respond_to?(:tempfile)
          return render json: { error: 'Image parameter is required' }, status: :bad_request
        end

        features = params[:features]&.split(',')&.map(&:strip)&.map(&:to_sym) || %i[labels text]

        results = analyze_image(
          image_path: params[:image].tempfile.path,
          features: features,
        )

        render json: results
      end

      # POST /api/v1/vision/detect_menu_items
      # Specialized endpoint to detect menu items from an image
      #
      # Parameters:
      #   - image: The image file containing a menu (required)
      #   - min_confidence: Minimum confidence score (0-1) for text detection (optional, default: 0.7)
      #
      # Example request:
      #   POST /api/v1/vision/detect_menu_items
      #   Headers: Content-Type: multipart/form-data
      #   Body: { image: [binary image data] }
      def detect_menu_items
        unless params[:image].respond_to?(:tempfile)
          return render json: { error: 'Image parameter is required' }, status: :bad_request
        end

        # First, extract text from the image
        text = analyze_image(
          image_path: params[:image].tempfile.path,
          features: [:text],
        )[:text]

        # Process the extracted text to identify menu items and prices
        menu_items = process_menu_text(text, params[:min_confidence]&.to_f || 0.7)

        render json: { menu_items: menu_items, raw_text: text }
      end

      private

      # Process extracted text to identify menu items and prices
      def process_menu_text(text, min_confidence)
        # This is a simplified example - you'll need to customize this based on your menu format
        lines = text.split("\n").map(&:strip).compact_blank

        menu_items = []
        current_item = nil

        # Simple heuristic: lines with prices are menu items
        price_regex = /\$\d+(\.\d{2})?|\d+\s*(?:dollars?|€|£|¥|Rs\.?|Rs)/i

        lines.each do |line|
          if line.match?(price_regex)
            # If we have a current item, save it before starting a new one
            menu_items << current_item if current_item

            # Extract price and name
            price_match = line.match(price_regex).to_s
            name = line.gsub(price_match, '').strip

            current_item = {
              name: name,
              price: price_match,
              description: nil,
              confidence: 1.0, # This would be calculated based on detection confidence
            }
          elsif current_item && line.present?
            # Add line to the current item's description
            current_item[:description] ||= ''
            current_item[:description] += "#{line} "
          end
        end

        # Add the last item if exists
        menu_items << current_item if current_item

        # Filter by confidence if needed
        menu_items.select { |item| item[:confidence] >= min_confidence }
      end
    end
  end
end
