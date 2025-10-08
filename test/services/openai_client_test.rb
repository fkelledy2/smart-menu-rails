require 'test_helper'

class OpenaiClientTest < ActiveSupport::TestCase
  def setup
    @client = OpenaiClient.new
    @valid_prompt = "A beautiful sunset over mountains"
    @test_image_path = Rails.root.join('test', 'fixtures', 'files', 'test_image.png')
    
    # Create test image file if it doesn't exist
    create_test_image_file unless File.exist?(@test_image_path)
  end

  def teardown
    # Clean up any test files if needed
  end

  # Inheritance and structure tests
  test "should inherit from ExternalApiClient" do
    assert_kind_of ExternalApiClient, @client
  end

  test "should include HTTParty" do
    assert OpenaiClient.include?(HTTParty)
  end

  test "should define custom exception classes" do
    assert_kind_of Class, OpenaiClient::ImageGenerationError
    assert_kind_of Class, OpenaiClient::InvalidPromptError
    assert_kind_of Class, OpenaiClient::ModelNotFoundError
    assert_kind_of Class, OpenaiClient::QuotaExceededError
    
    # Should inherit from appropriate base classes
    assert OpenaiClient::ImageGenerationError < ExternalApiClient::ApiError
    assert OpenaiClient::InvalidPromptError < ExternalApiClient::Error
    assert OpenaiClient::ModelNotFoundError < ExternalApiClient::Error
    assert OpenaiClient::QuotaExceededError < ExternalApiClient::RateLimitError
  end

  test "should define image models configuration" do
    assert_instance_of Hash, OpenaiClient::IMAGE_MODELS
    assert_includes OpenaiClient::IMAGE_MODELS.keys, 'dall-e-2'
    assert_includes OpenaiClient::IMAGE_MODELS.keys, 'dall-e-3'
    
    # Check DALL-E 2 configuration
    dalle2_config = OpenaiClient::IMAGE_MODELS['dall-e-2']
    assert_equal '1024x1024', dalle2_config[:max_size]
    assert_includes dalle2_config[:sizes], '256x256'
    assert_includes dalle2_config[:sizes], '512x512'
    assert_includes dalle2_config[:sizes], '1024x1024'
    
    # Check DALL-E 3 configuration
    dalle3_config = OpenaiClient::IMAGE_MODELS['dall-e-3']
    assert_equal '1792x1024', dalle3_config[:max_size]
    assert_includes dalle3_config[:sizes], '1024x1024'
    assert_includes dalle3_config[:sizes], '1792x1024'
    assert_includes dalle3_config[:sizes], '1024x1792'
  end

  # Configuration tests
  test "should have correct default configuration" do
    config = @client.config
    
    assert_equal 'https://api.openai.com/v1', config[:base_uri]
    assert_equal 60.seconds, config[:timeout]
    assert_equal 2, config[:max_retries]
  end

  test "should validate configuration on initialization" do
    # Mock missing API key
    Rails.application.credentials.stub(:openai_api_key, nil) do
      ENV.stub(:fetch, nil) do
        error = assert_raises(ExternalApiClient::ConfigurationError) do
          OpenaiClient.new
        end
        
        assert_includes error.message, 'OpenAI API key is required'
      end
    end
  end

  test "should accept custom configuration" do
    custom_config = { timeout: 120.seconds, max_retries: 5 }
    client = OpenaiClient.new(custom_config)
    
    assert_equal 120.seconds, client.config[:timeout]
    assert_equal 5, client.config[:max_retries]
  end

  # Image generation tests
  test "should generate images with default parameters" do
    mock_successful_response = mock_openai_image_response([
      { 'url' => 'https://example.com/image1.png', 'revised_prompt' => @valid_prompt }
    ])

    @client.stub(:post, mock_successful_response) do
      result = @client.generate_images(@valid_prompt)
      
      assert_instance_of Hash, result
      assert_includes result.keys, :created
      assert_includes result.keys, :data
      assert_instance_of Array, result[:data]
      assert_equal 1, result[:data].length
      
      image_data = result[:data].first
      assert_equal 'https://example.com/image1.png', image_data[:url]
      assert_equal @valid_prompt, image_data[:revised_prompt]
    end
  end

  test "should generate images with custom parameters" do
    captured_request = nil
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/image1.png', 'revised_prompt' => @valid_prompt }
      ])
    end

    @client.stub(:post, mock_post) do
      @client.generate_images(@valid_prompt, n: 2, size: '512x512', model: 'dall-e-2', quality: 'hd')
      
      assert_equal '/images/generations', captured_request[:path]
      
      body = JSON.parse(captured_request[:options][:body])
      assert_equal 'dall-e-2', body['model']
      assert_equal @valid_prompt, body['prompt']
      assert_equal 2, body['n']
      assert_equal '512x512', body['size']
      assert_equal 'url', body['response_format']
      # Quality should not be included for DALL-E 2
      assert_nil body['quality']
    end
  end

  test "should include quality parameter for DALL-E 3" do
    captured_request = nil
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/image1.png', 'revised_prompt' => @valid_prompt }
      ])
    end

    @client.stub(:post, mock_post) do
      @client.generate_images(@valid_prompt, model: 'dall-e-3', quality: 'hd')
      
      body = JSON.parse(captured_request[:options][:body])
      assert_equal 'dall-e-3', body['model']
      assert_equal 'hd', body['quality']
    end
  end

  test "should generate multiple images with DALL-E 2" do
    mock_successful_response = mock_openai_image_response([
      { 'url' => 'https://example.com/image1.png', 'revised_prompt' => @valid_prompt },
      { 'url' => 'https://example.com/image2.png', 'revised_prompt' => @valid_prompt }
    ])

    @client.stub(:post, mock_successful_response) do
      result = @client.generate_images(@valid_prompt, n: 2, model: 'dall-e-2')
      
      assert_equal 2, result[:data].length
      assert_equal 'https://example.com/image1.png', result[:data][0][:url]
      assert_equal 'https://example.com/image2.png', result[:data][1][:url]
    end
  end

  # Image variations tests
  test "should create image variations" do
    captured_request = nil
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/variation1.png', 'revised_prompt' => nil }
      ])
    end

    @client.stub(:post, mock_post) do
      result = @client.create_image_variations(@test_image_path.to_s)
      
      assert_equal '/images/variations', captured_request[:path]
      assert_instance_of File, captured_request[:options][:body][:image]
      assert_equal 1, captured_request[:options][:body][:n]
      assert_equal '1024x1024', captured_request[:options][:body][:size]
      assert_equal 'url', captured_request[:options][:body][:response_format]
      
      assert_instance_of Hash, result
      assert_equal 1, result[:data].length
      assert_equal 'https://example.com/variation1.png', result[:data].first[:url]
    end
  end

  test "should create multiple image variations" do
    captured_request = nil
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/variation1.png', 'revised_prompt' => nil },
        { 'url' => 'https://example.com/variation2.png', 'revised_prompt' => nil }
      ])
    end

    @client.stub(:post, mock_post) do
      result = @client.create_image_variations(@test_image_path.to_s, n: 2, size: '512x512')
      
      assert_equal 2, captured_request[:options][:body][:n]
      assert_equal '512x512', captured_request[:options][:body][:size]
      assert_equal 2, result[:data].length
    end
  end

  # Image editing tests
  test "should edit image without mask" do
    captured_request = nil
    edit_prompt = "Add a rainbow to the sky"
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/edited1.png', 'revised_prompt' => edit_prompt }
      ])
    end

    @client.stub(:post, mock_post) do
      result = @client.edit_image(@test_image_path.to_s, edit_prompt)
      
      assert_equal '/images/edits', captured_request[:path]
      assert_instance_of File, captured_request[:options][:body][:image]
      assert_equal edit_prompt, captured_request[:options][:body][:prompt]
      assert_equal 1, captured_request[:options][:body][:n]
      assert_equal '1024x1024', captured_request[:options][:body][:size]
      assert_nil captured_request[:options][:body][:mask]
      
      assert_instance_of Hash, result
      assert_equal edit_prompt, result[:data].first[:revised_prompt]
    end
  end

  test "should edit image with mask" do
    mask_path = @test_image_path.to_s # Using same file as mask for testing
    captured_request = nil
    edit_prompt = "Remove the background"
    
    mock_post = lambda do |path, options|
      captured_request = { path: path, options: options }
      mock_openai_image_response([
        { 'url' => 'https://example.com/edited1.png', 'revised_prompt' => edit_prompt }
      ])
    end

    @client.stub(:post, mock_post) do
      result = @client.edit_image(@test_image_path.to_s, edit_prompt, mask_path: mask_path)
      
      assert_instance_of File, captured_request[:options][:body][:image]
      assert_instance_of File, captured_request[:options][:body][:mask]
      assert_equal edit_prompt, captured_request[:options][:body][:prompt]
    end
  end

  # Models endpoint test
  test "should fetch available models" do
    mock_models_response = mock_openai_models_response([
      { 'id' => 'dall-e-2', 'object' => 'model', 'created' => 1677649963 },
      { 'id' => 'dall-e-3', 'object' => 'model', 'created' => 1698785189 }
    ])

    @client.stub(:get, mock_models_response) do
      models = @client.models
      
      assert_instance_of Array, models
      assert_equal 2, models.length
      assert_equal 'dall-e-2', models[0]['id']
      assert_equal 'dall-e-3', models[1]['id']
    end
  end

  # Validation tests
  test "should validate prompt is not blank" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images('')
    end
    
    assert_equal 'Prompt cannot be blank', error.message
  end

  test "should validate prompt length" do
    long_prompt = 'A' * 1001
    
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images(long_prompt)
    end
    
    assert_equal 'Prompt too long (max 1000 characters)', error.message
  end

  test "should validate model exists" do
    error = assert_raises(OpenaiClient::ModelNotFoundError) do
      @client.generate_images(@valid_prompt, model: 'invalid-model')
    end
    
    assert_equal 'Unsupported model: invalid-model', error.message
  end

  test "should validate size for model" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images(@valid_prompt, model: 'dall-e-2', size: '1792x1024')
    end
    
    assert_includes error.message, 'Unsupported size 1792x1024 for model dall-e-2'
  end

  test "should validate n parameter for DALL-E 2" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images(@valid_prompt, model: 'dall-e-2', n: 11)
    end
    
    assert_includes error.message, 'Invalid n value: 11 (max 10 for dall-e-2)'
  end

  test "should validate n parameter for DALL-E 3" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images(@valid_prompt, model: 'dall-e-3', n: 2)
    end
    
    assert_includes error.message, 'Invalid n value: 2 (max 1 for dall-e-3)'
  end

  test "should validate n parameter minimum" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.generate_images(@valid_prompt, n: 0)
    end
    
    assert_includes error.message, 'Invalid n value: 0'
  end

  test "should validate image file exists" do
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.create_image_variations('/nonexistent/file.png')
    end
    
    assert_includes error.message, 'Image file not found'
  end

  test "should validate image file size" do
    # Mock File.size to return large size
    File.stub(:size, 5.megabytes) do
      error = assert_raises(OpenaiClient::InvalidPromptError) do
        @client.create_image_variations(@test_image_path.to_s)
      end
      
      assert_equal 'Image file too large (max 4MB)', error.message
    end
  end

  test "should validate image file format" do
    invalid_file = Rails.root.join('test', 'fixtures', 'files', 'test.txt')
    FileUtils.touch(invalid_file) unless File.exist?(invalid_file)
    
    error = assert_raises(OpenaiClient::InvalidPromptError) do
      @client.create_image_variations(invalid_file.to_s)
    end
    
    assert_includes error.message, 'Unsupported image format: .txt'
  ensure
    File.delete(invalid_file) if File.exist?(invalid_file)
  end

  test "should allow valid image formats" do
    valid_extensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif']
    
    valid_extensions.each do |ext|
      test_file = Rails.root.join('test', 'fixtures', 'files', "test#{ext}")
      FileUtils.touch(test_file) unless File.exist?(test_file)
      
      # Should not raise error for valid extensions
      File.stub(:size, 1.megabyte) do
        mock_response = mock_openai_image_response([
          { 'url' => 'https://example.com/variation.png', 'revised_prompt' => nil }
        ])
        
        @client.stub(:post, mock_response) do
          assert_nothing_raised do
            @client.create_image_variations(test_file.to_s)
          end
        end
      end
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end
  end

  # Error handling tests
  test "should handle API errors in image generation" do
    mock_error_response = mock_openai_error_response(400, 'Bad request')
    
    @client.stub(:post, ->(*args) { raise ExternalApiClient::ApiError.new('API Error') }) do
      error = assert_raises(OpenaiClient::ImageGenerationError) do
        @client.generate_images(@valid_prompt)
      end
      
      assert_includes error.message, 'Image generation failed'
    end
  end

  test "should handle content policy violations" do
    @client.stub(:post, ->(*args) { raise ExternalApiClient::ApiError.new('content policy violation') }) do
      error = assert_raises(OpenaiClient::InvalidPromptError) do
        @client.generate_images('inappropriate content')
      end
      
      assert_equal 'Prompt violates OpenAI content policy', error.message
    end
  end

  test "should handle billing/quota errors" do
    @client.stub(:post, ->(*args) { raise ExternalApiClient::ApiError.new('billing limit exceeded') }) do
      error = assert_raises(OpenaiClient::QuotaExceededError) do
        @client.generate_images(@valid_prompt)
      end
      
      assert_equal 'OpenAI quota or billing issue', error.message
    end
  end

  test "should handle empty response data" do
    mock_empty_response = mock_openai_image_response([])
    
    @client.stub(:post, mock_empty_response) do
      error = assert_raises(OpenaiClient::ImageGenerationError) do
        @client.generate_images(@valid_prompt)
      end
      
      assert_includes error.message, 'No images generated'
    end
  end

  test "should handle malformed response data" do
    mock_malformed_response = Object.new
    mock_malformed_response.define_singleton_method(:parsed_response) { {} }
    
    @client.stub(:post, mock_malformed_response) do
      error = assert_raises(OpenaiClient::ImageGenerationError) do
        @client.generate_images(@valid_prompt)
      end
      
      assert_includes error.message, 'No images generated'
    end
  end

  # Response handling tests
  test "should handle 400 error with billing message" do
    mock_response = Object.new
    mock_response.define_singleton_method(:code) { 400 }
    mock_response.define_singleton_method(:parsed_response) do
      { 'error' => { 'message' => 'billing limit exceeded' } }
    end
    
    # The method should raise QuotaExceededError for billing issues in 400 responses
    error = assert_raises(OpenaiClient::QuotaExceededError) do
      @client.send(:handle_response, mock_response)
    end
    
    assert_includes error.message, 'OpenAI quota exceeded'
  end

  test "should handle 400 error without billing message" do
    mock_response = Object.new
    mock_response.define_singleton_method(:code) { 400 }
    mock_response.define_singleton_method(:parsed_response) do
      { 'error' => { 'message' => 'invalid request' } }
    end
    
    error = assert_raises(ExternalApiClient::ApiError) do
      @client.send(:handle_response, mock_response)
    end
    
    assert_includes error.message, 'Bad request: invalid request'
  end

  test "should handle 429 rate limit error" do
    mock_response = Object.new
    mock_response.define_singleton_method(:code) { 429 }
    mock_response.define_singleton_method(:body) { 'Rate limit exceeded' }
    
    error = assert_raises(ExternalApiClient::RateLimitError) do
      @client.send(:handle_response, mock_response)
    end
    
    assert_equal 'OpenAI rate limit exceeded', error.message
  end

  # Authentication tests
  test "should use API key from credentials" do
    test_key = 'sk-test123'
    Rails.application.credentials.stub(:openai_api_key, test_key) do
      client = OpenaiClient.new
      auth_headers = client.send(:auth_headers)
      
      assert_equal "Bearer #{test_key}", auth_headers['Authorization']
    end
  end

  test "should use API key from environment variable" do
    test_key = 'sk-env123'
    Rails.application.credentials.stub(:openai_api_key, nil) do
      ENV.stub(:fetch, test_key) do
        client = OpenaiClient.new
        auth_headers = client.send(:auth_headers)
        
        assert_equal "Bearer #{test_key}", auth_headers['Authorization']
      end
    end
  end

  # Integration tests
  test "should handle complete image generation workflow" do
    mock_response = mock_openai_image_response([
      { 'url' => 'https://example.com/generated.png', 'revised_prompt' => 'A beautiful enhanced sunset' }
    ])

    @client.stub(:post, mock_response) do
      result = @client.generate_images(@valid_prompt, n: 1, size: '1024x1024', model: 'dall-e-3', quality: 'hd')
      
      assert_instance_of Hash, result
      assert_instance_of Integer, result[:created]
      assert_instance_of Array, result[:data]
      assert_equal 1, result[:data].length
      
      image = result[:data].first
      assert_equal 'https://example.com/generated.png', image[:url]
      assert_equal 'A beautiful enhanced sunset', image[:revised_prompt]
    end
  end

  test "should handle complete image variation workflow" do
    mock_response = mock_openai_image_response([
      { 'url' => 'https://example.com/variation.png', 'revised_prompt' => nil }
    ])

    @client.stub(:post, mock_response) do
      result = @client.create_image_variations(@test_image_path.to_s, n: 1, size: '512x512')
      
      assert_instance_of Hash, result
      assert_equal 1, result[:data].length
      assert_equal 'https://example.com/variation.png', result[:data].first[:url]
    end
  end

  test "should handle complete image editing workflow" do
    mock_response = mock_openai_image_response([
      { 'url' => 'https://example.com/edited.png', 'revised_prompt' => 'Enhanced image with edits' }
    ])

    @client.stub(:post, mock_response) do
      result = @client.edit_image(@test_image_path.to_s, 'Add more colors', n: 1, size: '1024x1024')
      
      assert_instance_of Hash, result
      assert_equal 1, result[:data].length
      assert_equal 'https://example.com/edited.png', result[:data].first[:url]
      assert_equal 'Enhanced image with edits', result[:data].first[:revised_prompt]
    end
  end

  private

  def create_test_image_file
    FileUtils.mkdir_p(File.dirname(@test_image_path))
    
    # Create a minimal PNG file (1x1 pixel)
    png_data = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, # PNG signature
      0x00, 0x00, 0x00, 0x0D, # IHDR chunk length
      0x49, 0x48, 0x44, 0x52, # IHDR
      0x00, 0x00, 0x00, 0x01, # Width: 1
      0x00, 0x00, 0x00, 0x01, # Height: 1
      0x08, 0x02, 0x00, 0x00, 0x00, # Bit depth, color type, compression, filter, interlace
      0x90, 0x77, 0x53, 0xDE, # CRC
      0x00, 0x00, 0x00, 0x0C, # IDAT chunk length
      0x49, 0x44, 0x41, 0x54, # IDAT
      0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, # Image data
      0x02, 0x00, 0x01, 0x00, # CRC
      0x00, 0x00, 0x00, 0x00, # IEND chunk length
      0x49, 0x45, 0x4E, 0x44, # IEND
      0xAE, 0x42, 0x60, 0x82  # CRC
    ].pack('C*')
    
    File.binwrite(@test_image_path, png_data)
  end

  def mock_openai_image_response(images)
    mock_response = Object.new
    mock_response.define_singleton_method(:parsed_response) do
      {
        'created' => Time.current.to_i,
        'data' => images
      }
    end
    mock_response
  end

  def mock_openai_models_response(models)
    mock_response = Object.new
    mock_response.define_singleton_method(:parsed_response) do
      { 'data' => models }
    end
    mock_response
  end

  def mock_openai_error_response(status_code, message)
    mock_response = Object.new
    mock_response.define_singleton_method(:code) { status_code }
    mock_response.define_singleton_method(:body) { message }
    mock_response.define_singleton_method(:parsed_response) do
      { 'error' => { 'message' => message } }
    end
    mock_response
  end
end
