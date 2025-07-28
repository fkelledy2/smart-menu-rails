# frozen_string_literal: true

# Configure Google Cloud Vision
require "google/cloud/vision"

# Initialize the Vision client with credentials from environment variables
Google::Cloud::Vision.configure do |config|
  # Path to the service account JSON key file
  config.credentials = if Rails.application.credentials.gcp_vision_credentials.present?
    Rails.application.credentials.gcp_vision_credentials
  else
    # Fallback to environment variable or default credentials
    ENV["GOOGLE_APPLICATION_CREDENTIALS"] || 
    Rails.root.join("config/credentials/gcp_vision.json").to_s
  end
  
  # Optional: Set the project ID if not using default credentials
  # config.project_id = ENV["GOOGLE_CLOUD_PROJECT"]
  
  # Optional: Set the timeout
  # config.timeout = 60
  
  # Optional: Set the retry configuration
  # config.retry_policy = {
  #   initial_delay: 1.0,
  #   max_delay: 60.0,
  #   multiplier: 2.0,
  #   retry_codes: ["UNAVAILABLE", "DEADLINE_EXCEEDED"]
  # }
end

# Create a module to wrap the Vision API calls
module GoogleVision
  class Client
    class << self
      def client
        @client ||= Google::Cloud::Vision.image_annotator
      end
      
      # Example method to detect labels in an image
      def detect_labels(image_path)
        response = client.label_detection(
          image: image_path,
          max_results: 10 # Optional: limit the number of results
        )
        response.responses.flat_map(&:label_annotations)
      end
      
      # Example method to extract text from an image (OCR)
      def extract_text(image_path)
        response = client.text_detection(
          image: image_path
        )
        response.responses.flat_map(&:text_annotations).map(&:description).join("\n")
      end
      
      # Example method to detect web entities and pages
      def detect_web(image_path)
        response = client.web_detection(
          image: image_path
        )
        response.responses.first.web_detection
      end
      
      # Add more methods as needed for your specific use case
    end
  end
end
