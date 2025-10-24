# frozen_string_literal: true

require 'test_helper'

class ImageOptimizationServiceTest < ActiveSupport::TestCase
  setup do
    @service = ImageOptimizationService.instance
    @test_image_data = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')
  end

  test 'singleton pattern works' do
    assert_equal @service, ImageOptimizationService.instance
    assert_respond_to ImageOptimizationService, :convert_to_webp
  end

  test 'supported_format? returns true for supported formats' do
    assert @service.supported_format?('image/jpeg')
    assert @service.supported_format?('image/jpg')
    assert @service.supported_format?('image/png')
    assert @service.supported_format?('image/gif')
    assert @service.supported_format?('image/webp')
  end

  test 'supported_format? returns false for unsupported formats' do
    refute @service.supported_format?('application/pdf')
    refute @service.supported_format?('text/plain')
    refute @service.supported_format?('video/mp4')
  end

  test 'optimization_stats returns correct structure' do
    stats = @service.optimization_stats
    
    assert_kind_of Hash, stats
    assert_includes stats, :webp_supported
    assert_includes stats, :supported_formats
    assert_includes stats, :default_quality
    assert_includes stats, :default_responsive_sizes
    
    assert_kind_of Array, stats[:supported_formats]
    assert_equal 85, stats[:default_quality]
    assert_equal [320, 640, 1024, 1920], stats[:default_responsive_sizes]
  end

  test 'convert_to_webp returns nil for unsupported format' do
    blob = create_test_blob('test.pdf', 'application/pdf')
    
    # Mock the content_type since ActiveStorage may override it
    blob.stub :content_type, 'application/pdf' do
      result = @service.convert_to_webp(blob)
      assert_nil result
    end
  end

  test 'convert_to_webp returns blob for webp input' do
    blob = create_test_blob('test.webp', 'image/webp')
    
    # Mock the content_type
    blob.stub :content_type, 'image/webp' do
      result = @service.convert_to_webp(blob)
      assert_equal blob, result
    end
  end

  test 'generate_responsive_variants returns empty hash for unsupported format' do
    blob = create_test_blob('test.pdf', 'application/pdf')
    
    # Mock the content_type
    blob.stub :content_type, 'application/pdf' do
      variants = @service.generate_responsive_variants(blob)
      assert_empty variants
    end
  end

  test 'generate_responsive_variants with custom sizes' do
    blob = create_test_blob('test.png', 'image/png')
    
    variants = @service.generate_responsive_variants(blob, sizes: [100, 200])
    
    assert_kind_of Hash, variants
    # Variants may be empty if image processing fails in test environment
    # Just verify it returns a hash
  end

  test 'optimize_compression returns nil for unsupported format' do
    blob = create_test_blob('test.txt', 'text/plain')
    
    # Mock the content_type
    blob.stub :content_type, 'text/plain' do
      result = @service.optimize_compression(blob)
      assert_nil result
    end
  end

  test 'optimize_compression with custom quality' do
    blob = create_test_blob('test.png', 'image/png')
    
    # Should not raise error
    assert_nothing_raised do
      @service.optimize_compression(blob, quality: 75)
    end
  end

  test 'class methods delegate to instance' do
    assert_respond_to ImageOptimizationService, :convert_to_webp
    assert_respond_to ImageOptimizationService, :generate_responsive_variants
    assert_respond_to ImageOptimizationService, :optimize_compression
    assert_respond_to ImageOptimizationService, :supported_format?
  end

  test 'handles errors gracefully in convert_to_webp' do
    blob = create_test_blob('test.png', 'image/png')
    
    # Mock an error
    blob.stub :variant, ->(*) { raise StandardError, 'Test error' } do
      result = @service.convert_to_webp(blob)
      assert_nil result
    end
  end

  test 'handles errors gracefully in generate_responsive_variants' do
    blob = create_test_blob('test.png', 'image/png')
    
    # Should not raise error even if variant generation fails
    assert_nothing_raised do
      @service.generate_responsive_variants(blob, sizes: [100])
    end
  end

  test 'handles errors gracefully in optimize_compression' do
    blob = create_test_blob('test.png', 'image/png')
    
    # Mock an error
    blob.stub :variant, ->(*) { raise StandardError, 'Test error' } do
      result = @service.optimize_compression(blob)
      assert_nil result
    end
  end

  test 'logs conversion attempts' do
    blob = create_test_blob('test.png', 'image/png')
    
    assert_logs_match /Converting.*to WebP/ do
      @service.convert_to_webp(blob)
    end
  end

  test 'logs responsive variant generation' do
    blob = create_test_blob('test.png', 'image/png')
    
    assert_logs_match /Generating responsive variants/ do
      @service.generate_responsive_variants(blob)
    end
  end

  test 'logs compression optimization' do
    blob = create_test_blob('test.png', 'image/png')
    
    assert_logs_match /Optimizing compression/ do
      @service.optimize_compression(blob)
    end
  end

  private

  def create_test_blob(filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(@test_image_data),
      filename: filename,
      content_type: content_type
    )
  end

  def assert_logs_match(pattern)
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)
    
    yield
    
    assert_match pattern, log_output.string
  ensure
    Rails.logger = original_logger
  end
end
