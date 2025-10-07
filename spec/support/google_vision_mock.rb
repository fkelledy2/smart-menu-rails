# frozen_string_literal: true

# Mock Google Vision Service for testing
class MockGoogleVisionService
  def self.detect_labels(image_path)
    [
      { description: 'Food', score: 0.98 },
      { description: 'Menu', score: 0.95 },
      { description: 'Restaurant', score: 0.92 }
    ]
  end

  def self.detect_text(image_path)
    "Sample Menu\nPizza Margherita $12.99\nCaesar Salad $8.50\nGrilled Chicken $15.99"
  end

  def self.detect_web_entities(image_path)
    {
      web_entities: [
        { description: 'Pizza', score: 0.95 },
        { description: 'Italian Food', score: 0.88 }
      ]
    }
  end

  def self.detect_objects(image_path)
    [
      { name: 'Pizza', score: 0.95, bounding_box: { x: 100, y: 100, width: 200, height: 150 } }
    ]
  end

  def self.detect_landmarks(image_path)
    []
  end
end

# Mock the GoogleVisionService in test environment
if Rails.env.test?
  # Replace the entire GoogleVisionService class with mock implementation
  Object.send(:remove_const, :GoogleVisionService) if defined?(GoogleVisionService)
  
  class GoogleVisionService
    def self.detect_labels(image_path)
      MockGoogleVisionService.detect_labels(image_path)
    end

    def self.detect_text(image_path)
      MockGoogleVisionService.detect_text(image_path)
    end

    def self.detect_web_entities(image_path)
      MockGoogleVisionService.detect_web_entities(image_path)
    end

    def self.detect_objects(image_path)
      MockGoogleVisionService.detect_objects(image_path)
    end

    def self.detect_landmarks(image_path)
      MockGoogleVisionService.detect_landmarks(image_path)
    end
  end
end
