# frozen_string_literal: true

module GoogleVisionAnalyzable
  extend ActiveSupport::Concern

  included do
    rescue_from GoogleVisionService::Error, with: :handle_vision_error
  end

  # Analyze an image using Google Vision API
  # @param image_path [String] Path to the image file
  # @param image_content [String] Raw image content as a string
  # @param features [Array<Symbol>] Features to detect (e.g., [:labels, :text, :web, :objects, :landmarks])
  # @return [Hash] Analysis results
  def analyze_image(image_path: nil, image_content: nil, features: [:labels, :text])
    vision_service = GoogleVisionService.new(
      image_path: image_path,
      image_content: image_content
    )

    results = {}
    features.each do |feature|
      results[feature] = case feature.to_sym
                         when :labels then vision_service.detect_labels
                         when :text then vision_service.extract_text
                         when :web then vision_service.detect_web
                         when :objects then vision_service.detect_objects
                         when :landmarks then vision_service.detect_landmarks
                         else
                           Rails.logger.warn("Unknown Google Vision feature: #{feature}")
                           nil
                         end
    end

    results
  end

  private

  def handle_vision_error(exception)
    Rails.logger.error("Google Vision Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    
    error_message = case exception
                    when GoogleVisionService::ConfigurationError
                      "Configuration error: #{exception.message}"
                    when GoogleVisionService::ApiError
                      "API error: #{exception.message}"
                    else
                      "Error processing image: #{exception.message}"
                    end
    
    render json: { error: error_message }, status: :unprocessable_entity
  end
end
