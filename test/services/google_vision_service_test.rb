require 'test_helper'

class GoogleVisionServiceTest < ActiveSupport::TestCase
  def setup
    @image_path = Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')
    @image_content = { content: 'fake_image_data' }
  end

  # Initialization tests
  test 'should initialize with image_path' do
    service = GoogleVisionService.new(image_path: @image_path.to_s)
    assert_equal @image_path.to_s, service.send(:image_path)
  end

  test 'should initialize with image_content' do
    service = GoogleVisionService.new(image_content: @image_content)
    assert_equal @image_content, service.send(:image_content)
  end

  test 'should raise ConfigurationError when no image provided' do
    assert_raises(GoogleVisionService::ConfigurationError) do
      GoogleVisionService.new
    end
  end

  test 'should raise ConfigurationError with appropriate message' do
    error = assert_raises(GoogleVisionService::ConfigurationError) do
      GoogleVisionService.new
    end
    assert_equal 'Either image_path or image_content must be provided', error.message
  end

  # Image source tests
  test 'should use image_content when provided' do
    service = GoogleVisionService.new(image_content: @image_content)
    assert_equal @image_content, service.send(:image_source)
  end

  test 'should read file when image_path provided' do
    # Create a temporary test file
    test_file = Tempfile.new(['test', '.jpg'])
    test_file.write('test image data')
    test_file.close

    service = GoogleVisionService.new(image_path: test_file.path)

    File.stub(:binread, 'test image data') do
      image_source = service.send(:image_source)
      assert_equal({ content: 'test image data' }, image_source)
    end

    test_file.unlink
  end

  test 'should raise ConfigurationError when accessing image_source without image' do
    service = GoogleVisionService.new(image_content: @image_content)
    service.instance_variable_set(:@image_content, nil)
    service.instance_variable_set(:@image_path, nil)

    error = assert_raises(GoogleVisionService::ConfigurationError) do
      service.send(:image_source)
    end
    assert_equal 'Either image_path or image_content must be provided', error.message
  end

  # Response processing tests
  test 'should process response successfully' do
    service = GoogleVisionService.new(image_content: @image_content)

    mock_annotation = OpenStruct.new(description: 'test')
    mock_response_obj = OpenStruct.new(label_annotations: [mock_annotation])
    response = OpenStruct.new(responses: [mock_response_obj])

    result = service.send(:process_response, response, :label_annotations)
    assert_equal [mock_annotation], result
  end

  test 'should raise ApiError for empty response' do
    service = GoogleVisionService.new(image_content: @image_content)
    response = OpenStruct.new(responses: [])

    error = assert_raises(GoogleVisionService::ApiError) do
      service.send(:process_response, response, :label_annotations)
    end
    assert_equal 'Empty response from Google Vision API', error.message
  end

  test 'should raise ApiError for unexpected response format' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock response that will cause NoMethodError when accessing nonexistent_key
    mock_response_obj = Object.new
    response = OpenStruct.new(responses: [mock_response_obj])

    error = assert_raises(GoogleVisionService::ApiError) do
      service.send(:process_response, response, :nonexistent_key)
    end
    assert_equal 'Unexpected response format from Google Vision API', error.message
  end

  # Error class tests
  test 'should define custom error classes' do
    assert GoogleVisionService::Error < StandardError
    assert GoogleVisionService::ConfigurationError < GoogleVisionService::Error
    assert GoogleVisionService::ApiError < GoogleVisionService::Error
  end

  # API method error handling tests (without external API calls)
  test 'should handle Google Cloud errors in detect_labels' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock the client to raise a Google::Cloud::Error
    mock_client = Object.new
    def mock_client.label_detection(*_args)
      raise Google::Cloud::Error, 'API Error'
    end

    service.stub(:client, mock_client) do
      error = assert_raises(GoogleVisionService::ApiError) do
        service.detect_labels
      end
      assert_includes error.message, 'Failed to detect labels'
    end
  end

  test 'should handle Google Cloud errors in extract_text' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock the client to raise a Google::Cloud::Error
    mock_client = Object.new
    def mock_client.text_detection(*_args)
      raise Google::Cloud::Error, 'API Error'
    end

    service.stub(:client, mock_client) do
      error = assert_raises(GoogleVisionService::ApiError) do
        service.extract_text
      end
      assert_includes error.message, 'Failed to extract text'
    end
  end

  test 'should handle Google Cloud errors in detect_web' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock the client to raise a Google::Cloud::Error
    mock_client = Object.new
    def mock_client.web_detection(*_args)
      raise Google::Cloud::Error, 'API Error'
    end

    service.stub(:client, mock_client) do
      error = assert_raises(GoogleVisionService::ApiError) do
        service.detect_web
      end
      assert_includes error.message, 'Failed to detect web entities'
    end
  end

  test 'should handle Google Cloud errors in detect_objects' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock the client to raise a Google::Cloud::Error
    mock_client = Object.new
    def mock_client.object_localization(*_args)
      raise Google::Cloud::Error, 'API Error'
    end

    service.stub(:client, mock_client) do
      error = assert_raises(GoogleVisionService::ApiError) do
        service.detect_objects
      end
      assert_includes error.message, 'Failed to detect objects'
    end
  end

  test 'should handle Google Cloud errors in detect_landmarks' do
    service = GoogleVisionService.new(image_content: @image_content)

    # Mock the client to raise a Google::Cloud::Error
    mock_client = Object.new
    def mock_client.landmark_detection(*_args)
      raise Google::Cloud::Error, 'API Error'
    end

    service.stub(:client, mock_client) do
      error = assert_raises(GoogleVisionService::ApiError) do
        service.detect_landmarks
      end
      assert_includes error.message, 'Failed to detect landmarks'
    end
  end
end
