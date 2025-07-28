# frozen_string_literal: true

class GoogleVisionService
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end

  # Initialize with an optional image path or content
  def initialize(image_path: nil, image_content: nil)
    @image_path = image_path
    @image_content = image_content
    validate_initialization
  end

  # Detect labels in the image
  def detect_labels(max_results: 10)
    response = client.label_detection(
      image: image_source,
      max_results: max_results
    )
    process_response(response, :label_annotations)
  rescue Google::Cloud::Error => e
    raise ApiError, "Failed to detect labels: #{e.message}"
  end

  # Extract text from the image (OCR)
  def extract_text
    response = client.text_detection(image: image_source)
    texts = process_response(response, :text_annotations)
    texts.first&.description || ""
  rescue Google::Cloud::Error => e
    raise ApiError, "Failed to extract text: #{e.message}"
  end

  # Detect web entities and pages
  def detect_web
    response = client.web_detection(image: image_source)
    process_response(response, :web_detection)
  rescue Google::Cloud::Error => e
    raise ApiError, "Failed to detect web entities: #{e.message}"
  end

  # Detect objects in the image
  def detect_objects(max_results: 10)
    response = client.object_localization(
      image: image_source,
      max_results: max_results
    )
    process_response(response, :localized_object_annotations)
  rescue Google::Cloud::Error => e
    raise ApiError, "Failed to detect objects: #{e.message}"
  end

  # Detect landmarks in the image
  def detect_landmarks
    response = client.landmark_detection(image: image_source)
    process_response(response, :landmark_annotations)
  rescue Google::Cloud::Error => e
    raise ApiError, "Failed to detect landmarks: #{e.message}"
  end

  private

  attr_reader :image_path, :image_content

  def client
    @client ||= Google::Cloud::Vision.image_annotator
  end

  def image_source
    @image_source ||= if image_content.present?
      image_content
    elsif image_path.present?
      { content: File.binread(image_path) }
    else
      raise ConfigurationError, "Either image_path or image_content must be provided"
    end
  end

  def validate_initialization
    return if image_path.present? || image_content.present?
    raise ConfigurationError, "Either image_path or image_content must be provided"
  end

  def process_response(response, key)
    raise ApiError, "Empty response from Google Vision API" if response.responses.empty?
    response.responses.flat_map(&key)
  rescue NoMethodError
    raise ApiError, "Unexpected response format from Google Vision API"
  end
end
