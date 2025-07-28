# Smart Menu - Restaurant Management System

## Google Vision Integration

This application integrates with Google Cloud Vision API to provide advanced image analysis capabilities, particularly useful for menu digitization and analysis.

### Prerequisites

1. **Google Cloud Project**
   - Create a project in the [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the Cloud Vision API for your project
   - Create a service account and download the JSON key file

2. **Environment Setup**
   - Place your Google Cloud service account JSON key file at `config/credentials/gcp_vision.json`
   - Or, set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to your key file

### Configuration

1. **Initializer**
   - Configuration is handled in `config/initializers/google_cloud_vision.rb`
   - Customize timeouts, retry policies, and other settings as needed

2. **Environment Variables**
   - `GOOGLE_APPLICATION_CREDENTIALS`: Path to your service account JSON key file
   - `GOOGLE_CLOUD_PROJECT`: Your Google Cloud project ID (optional)

### Available Endpoints

#### 1. Analyze Image

Analyze an image for various features like labels, text, objects, etc.

```http
POST /api/v1/vision/analyze
Content-Type: multipart/form-data

{
  "image": [binary image data],
  "features": "labels,text,objects"
}
```

**Parameters:**
- `image`: (Required) The image file to analyze
- `features`: (Optional) Comma-separated list of features to detect. Available features:
  - `labels`: Detect objects and concepts in the image
  - `text`: Extract text using OCR
  - `web`: Detect web entities and pages
  - `objects`: Detect and localize objects
  - `landmarks`: Detect famous landmarks

---

#### 2. Detect Menu Items

Specialized endpoint to detect menu items and prices from an image.

```http
POST /api/v1/vision/detect_menu_items
Content-Type: multipart/form-data

{
  "image": [binary image data],
  "min_confidence": 0.7
}
```

**Parameters:**
- `image`: (Required) The menu image to analyze
- `min_confidence`: (Optional) Minimum confidence score (0-1) for text detection (default: 0.7)

### Usage Examples

#### Using the Service Directly

```ruby
# Initialize the service
vision_service = GoogleVisionService.new(image_path: 'path/to/image.jpg')

# Detect labels in the image
labels = vision_service.detect_labels(max_results: 5)

# Extract text from the image
text = vision_service.extract_text

# Detect web entities
web_entities = vision_service.detect_web

# Detect objects
objects = vision_service.detect_objects

# Detect landmarks
landmarks = vision_service.detect_landmarks
```

#### Using the Controller Concern

```ruby
class MyController < ApplicationController
  include GoogleVisionAnalyzable
  
  def analyze
    results = analyze_image(
      image_path: params[:image].tempfile.path,
      features: [:labels, :text, :objects]
    )
    
    render json: results
  end
end
```

### Error Handling

All Google Vision API calls are wrapped in error handling that will raise appropriate exceptions:

- `GoogleVisionService::ConfigurationError`: Issues with service configuration
- `GoogleVisionService::ApiError`: Errors returned by the Google Vision API
- `GoogleVisionService::Error`: Base error class for all Google Vision related errors

### Testing

1. **Unit Tests**
   - Test the service layer with mocked Google Vision API responses
   - Example tests are provided in `test/services/google_vision_service_test.rb`

2. **Integration Tests**
   - Test the API endpoints with real or mocked image data
   - Example tests are provided in `test/controllers/api/v1/vision_controller_test.rb`

### Performance Considerations

- **Image Size**: Larger images will take longer to process and cost more
- **Batch Processing**: For multiple images, consider using batch processing
- **Caching**: Cache results when possible to reduce API calls
- **Rate Limiting**: Be aware of Google's API rate limits

### Troubleshooting

1. **Authentication Errors**
   - Verify the service account JSON key file is valid and has the correct permissions
   - Check that the `GOOGLE_APPLICATION_CREDENTIALS` environment variable is set correctly

2. **API Errors**
   - Check the error message and status code from the API
   - Verify that the required APIs are enabled in your Google Cloud project

3. **Performance Issues**
   - Reduce image size before sending to the API
   - Implement client-side caching of results

### License

This integration is provided under the same license as the main application.

---

*For more information, refer to the [Google Cloud Vision API documentation](https://cloud.google.com/vision/docs).*
