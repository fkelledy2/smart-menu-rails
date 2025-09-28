# Smart Menu - Restaurant Management System

## Project-wide Best Practices Plan

This document outlines a project-wide plan to align the codebase with modern Rails best practices.

### Objectives
- Security: strong CSRF/session boundaries, authorization, secret hygiene.
- API: JSON endpoints under `Api::V1` with serializers and consistent error contracts.
- Testing: 90%+ line/branch coverage; service, job, controller, and policy tests.
- Database: foreign keys, NOT NULL/defaults, proper indexes, safe migrations.
- Performance: detect and fix N+1, pagination, mindful caching.
- Observability: Sentry via ENV (disabled in test), structured logging, basic metrics.
- CI/CD: add RuboCop, Brakeman, Bundler-Audit; enforce coverage gate.
- i18n/a11y: enforce i18n-tasks, translation coverage, accessible views.

### Phased Adoption Plan
1) Security & API boundaries (High) ✅ **COMPLETED**
   - Create `Api::V1` controllers for JSON endpoints.
   - Restore CSRF on HTML controllers; API uses `with: :null_session` and auth.
   - **Comprehensive Pundit authorization across ALL controllers** - not just OCR endpoints.
   - Create policies for all resource controllers (Restaurant, Menu, MenuItem, etc.).
   - Add `authenticate_user!`, `authorize`, and policy scopes to all sensitive actions.
   - Add request/policy tests for authorization coverage.

2) Secrets & configuration (High) ✅ **COMPLETED**
   - Ensure all secrets (Sentry, OpenAI, Google) come from credentials/ENV.
   - **Status**: Already well-implemented with Rails credentials and ENV fallbacks.

3) Testing to 90%+ (High) ✅ **COMPLETED**
   - Refactor `PdfMenuProcessor` for dependency injection; add unit tests with stubs.
   - Expand controller negative-path tests; add job idempotency tests.

4) API schema consistency (Medium) ✅ **COMPLETED**
   - Introduce serializers and a unified error format.
   - Centralize exception mapping in a base API controller.

5) Database hardening (High) ✅ **COMPLETED**
   - Add FKs, NOT NULL/defaults, and indexes; ship safe backfill migrations.
   - **Added**: NOT NULL constraints on critical fields with safe backfill.
   - **Added**: Composite indexes for common query patterns.

6) Architecture refactor (Medium)
   - Consolidate dietary restrictions into a single canonical source.
   - Extract external clients (OpenAI/Vision) into adapters with retries/timeouts.

7) Performance & observability (Medium)
   - Enable Bullet in dev/test; add structured logs and minimal metrics.

8) i18n & a11y (Low/Medium)
   - Add `i18n-tasks` to CI and ensure translation coverage.

9) CI/CD & tooling (Medium)
   - Add RuboCop, Brakeman, Bundler-Audit to CI; upload coverage artifacts.

### Security Implementation Status ✅ **IN PROGRESS**

**Completed:**
- ✅ API v1 controllers with Pundit authorization for OCR endpoints
- ✅ PdfMenuProcessor dependency injection with comprehensive unit tests  
- ✅ Database foreign keys and NOT NULL constraints with safe migrations
- ✅ Serializers and unified API error handling
- ✅ Secrets management via Rails credentials and ENV

**Currently Implementing:**
- 🔄 **Comprehensive Pundit authorization across ALL controllers**
  - RestaurantPolicy, MenuPolicy, MenuitemPolicy created
  - RestaurantsController partially updated with authorization
  - **Remaining**: Complete authorization for all 47+ controllers
  - **Scope**: Every controller that handles user data must have proper authorization

**Security Audit Required:**
- All controllers in `/app/controllers/` (47+ files)
- All policies in `/app/policies/` (expand from current 4 to ~15+ policies)
- All request specs for authorization coverage
- Ensure no controller bypasses authentication/authorization

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
