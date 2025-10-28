# frozen_string_literal: true

# Service for optimizing images for web delivery
# Handles WebP conversion, responsive variants, and compression
class ImageOptimizationService
  include Singleton

  class << self
    delegate :convert_to_webp, :generate_responsive_variants, :optimize_compression,
             :supported_format?, :webp_supported?, to: :instance
  end

  # Convert image to WebP format for better compression
  # @param blob [ActiveStorage::Blob] Original image blob
  # @param quality [Integer] WebP quality (1-100)
  # @return [ActiveStorage::Blob, nil] WebP variant blob or nil if conversion fails
  def convert_to_webp(blob, quality: 85)
    return nil unless supported_format?(blob.content_type)
    return blob if blob.content_type == 'image/webp'

    Rails.logger.info "[ImageOptimization] Converting #{blob.filename} to WebP (quality: #{quality})"

    begin
      # Use ActiveStorage variant for WebP conversion
      variant = blob.variant(
        format: :webp,
        saver: { quality: quality },
      )

      # Process the variant to generate the WebP version
      variant.processed

      Rails.logger.info '[ImageOptimization] Successfully converted to WebP'
      variant
    rescue StandardError => e
      Rails.logger.error "[ImageOptimization] WebP conversion failed: #{e.message}"
      nil
    end
  end

  # Generate responsive image variants at different sizes
  # @param blob [ActiveStorage::Blob] Original image blob
  # @param sizes [Array<Integer>] Target widths in pixels
  # @param quality [Integer] Image quality (1-100)
  # @return [Hash<Integer, ActiveStorage::Variant>] Variants by size
  def generate_responsive_variants(blob, sizes: [320, 640, 1024, 1920], quality: 85)
    return {} unless supported_format?(blob.content_type)

    Rails.logger.info "[ImageOptimization] Generating responsive variants for #{blob.filename}"

    variants = {}

    sizes.each do |width|
      variant = blob.variant(
        resize_to_limit: [width, nil],
        saver: { quality: quality },
      )

      variants[width] = variant.processed
      Rails.logger.debug { "[ImageOptimization] Generated #{width}px variant" }
    rescue StandardError => e
      Rails.logger.error "[ImageOptimization] Failed to generate #{width}px variant: #{e.message}"
    end

    Rails.logger.info "[ImageOptimization] Generated #{variants.size} responsive variants"
    variants
  end

  # Optimize image compression without changing format
  # @param blob [ActiveStorage::Blob] Original image blob
  # @param quality [Integer] Compression quality (1-100)
  # @return [ActiveStorage::Blob, nil] Optimized variant or nil if optimization fails
  def optimize_compression(blob, quality: 85)
    return nil unless supported_format?(blob.content_type)

    Rails.logger.info "[ImageOptimization] Optimizing compression for #{blob.filename} (quality: #{quality})"

    begin
      variant = blob.variant(
        saver: { quality: quality, strip: true },
      )

      variant.processed
      Rails.logger.info '[ImageOptimization] Successfully optimized compression'
      variant
    rescue StandardError => e
      Rails.logger.error "[ImageOptimization] Compression optimization failed: #{e.message}"
      nil
    end
  end

  # Check if image format is supported for optimization
  # @param content_type [String] MIME type
  # @return [Boolean] True if format is supported
  def supported_format?(content_type)
    %w[
      image/jpeg
      image/jpg
      image/png
      image/gif
      image/webp
    ].include?(content_type)
  end

  # Check if WebP format is supported by the system
  # @return [Boolean] True if WebP is supported
  def webp_supported?
    # Check if libvips supports WebP
    return @webp_supported if defined?(@webp_supported)

    @webp_supported = begin
      # Try to create a simple WebP variant
      test_blob = create_test_blob
      test_blob.variant(format: :webp).processed
      true
    rescue StandardError
      false
    end
  end

  # Get optimization statistics
  # @return [Hash] Optimization statistics
  def optimization_stats
    {
      webp_supported: webp_supported?,
      supported_formats: %w[jpeg jpg png gif webp],
      default_quality: 85,
      default_responsive_sizes: [320, 640, 1024, 1920],
    }
  end

  private

  # Create a test blob for capability testing
  # @return [ActiveStorage::Blob] Test blob
  def create_test_blob
    # Create a minimal 1x1 PNG blob for testing
    png_data = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')

    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(png_data),
      filename: 'test.png',
      content_type: 'image/png',
    )
  end
end
