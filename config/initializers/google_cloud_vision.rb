# frozen_string_literal: true

# Configure Google Cloud Vision
begin
  require "google/cloud/vision"
rescue LoadError
  # Gem not installed (e.g., during assets:precompile on CI) — skip configuring
end

# Initialize the Vision client with credentials from environment variables
if defined?(Google::Cloud::Vision)
  Google::Cloud::Vision.configure do |config|
  # Path to the service account JSON key file
  creds = nil

  # 1) Prefer Rails encrypted credentials if present (can be a Hash or JSON string)
  rails_creds = Rails.application.credentials.gcp_vision_credentials
  if rails_creds.present?
    creds = rails_creds
  else
    # 2) Allow inline JSON via env var (useful for CI/hosted environments)
    inline_json = ENV["GOOGLE_APPLICATION_CREDENTIALS_JSON"]
    if inline_json.present?
      begin
        creds = JSON.parse(inline_json)
      rescue JSON::ParserError
        Rails.logger.error "GOOGLE_APPLICATION_CREDENTIALS_JSON is not valid JSON"
      end
    end

    # 3) Otherwise use a file path from env var or a default local path
    creds ||= ENV["GOOGLE_APPLICATION_CREDENTIALS"] || Rails.root.join("config/credentials/gcp_vision.json").to_s
  end

  # In development, provide a helpful warning if a file path is configured but missing
  if Rails.env.development? && creds.is_a?(String)
    unless File.file?(creds)
      Rails.logger.warn "Google Cloud Vision credentials file not found at: #{creds}. " \
                        "Set Rails.credentials.gcp_vision_credentials, " \
                        "GOOGLE_APPLICATION_CREDENTIALS_JSON, or place the JSON at config/credentials/gcp_vision.json"
    end
  end

  config.credentials = creds
  
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
