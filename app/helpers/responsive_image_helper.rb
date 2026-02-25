# frozen_string_literal: true

# Helper for generating responsive and optimized image tags
module ResponsiveImageHelper
  # Generate responsive image tag with srcset for multiple sizes
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @param alt [String] Alt text for accessibility
  # @param sizes [String] Sizes attribute for responsive images
  # @param class_name [String] CSS class for the image
  # @param loading [String] Loading strategy ('lazy' or 'eager')
  # @param quality [Integer] Image quality (1-100)
  # @return [String] HTML image tag with srcset
  def responsive_image_tag(image, alt:, sizes: '100vw', class_name: '', loading: 'lazy', quality: 85)
    return '' if image.blank?

    # Handle Shrine uploads - use existing derivatives
    if shrine_upload?(image)
      derivatives = get_shrine_derivatives(image)

      srcset = if derivatives
                 [
                   derivatives[:thumb] ? "#{derivatives[:thumb].url} 200w" : nil,
                   derivatives[:medium] ? "#{derivatives[:medium].url} 600w" : nil,
                   derivatives[:large] ? "#{derivatives[:large].url} 1000w" : nil,
                 ].compact.join(', ')
               else
                 ''
               end

      src = derivatives && derivatives[:medium] ? derivatives[:medium].url : image.url

      return image_tag(
        src,
        alt: alt,
        srcset: srcset.presence,
        sizes: sizes,
        class: class_name,
        loading: loading,
        decoding: 'async',
      )
    end

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return '' if blob.blank?

    # Generate responsive variants
    variants = ImageOptimizationService.generate_responsive_variants(
      blob,
      sizes: [320, 640, 1024, 1920],
      quality: quality,
    )

    # Build srcset
    srcset_parts = variants.map do |width, variant|
      "#{url_for(variant)} #{width}w"
    end

    # Fallback to original if no variants
    src = variants.any? ? url_for(variants.values.first) : url_for(blob)
    srcset = srcset_parts.join(', ')

    # Generate image tag
    image_tag(
      src,
      alt: alt,
      srcset: srcset.presence,
      sizes: sizes,
      class: class_name,
      loading: loading,
      decoding: 'async',
    )
  end

  # Generate picture tag with WebP and fallback formats
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @param alt [String] Alt text for accessibility
  # @param sizes [String] Sizes attribute
  # @param class_name [String] CSS class
  # @param loading [String] Loading strategy
  # @param quality [Integer] Image quality
  # @return [String] HTML picture tag with WebP and fallback
  def picture_tag_with_webp(image, alt:, sizes: '100vw', class_name: '', loading: 'lazy', quality: 85, model: nil)
    return '' if image.blank?

    # Handle Shrine uploads differently from ActiveStorage
    if shrine_upload?(image)
      return picture_tag_for_shrine(image, alt: alt, sizes: sizes, class_name: class_name, loading: loading, model: model)
    end

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return '' if blob.blank?

    # Generate WebP variant
    webp_variant = ImageOptimizationService.convert_to_webp(blob, quality: quality)

    # Generate responsive variants for both WebP and original format
    webp_variants = if webp_variant
                      ImageOptimizationService.generate_responsive_variants(
                        webp_variant.blob,
                        quality: quality,
                      )
                    else
                      {}
                    end

    original_variants = ImageOptimizationService.generate_responsive_variants(
      blob,
      quality: quality,
    )

    # Build srcsets
    webp_srcset = webp_variants.map { |width, variant| "#{url_for(variant)} #{width}w" }.join(', ')
    original_srcset = original_variants.map { |width, variant| "#{url_for(variant)} #{width}w" }.join(', ')

    # Fallback URLs
    webp_src = webp_variants.any? ? url_for(webp_variants.values.first) : nil
    original_src = original_variants.any? ? url_for(original_variants.values.first) : url_for(blob)

    # Generate picture tag
    content_tag(:picture) do
      sources = []

      # WebP source
      if webp_src.present?
        sources << tag.source(srcset: webp_srcset.presence || webp_src,
                              sizes: sizes,
                              type: 'image/webp',)
      end

      # Original format source
      sources << tag.source(srcset: original_srcset.presence || original_src,
                            sizes: sizes,
                            type: blob.content_type,)

      # Fallback img tag
      sources << image_tag(
        original_src,
        alt: alt,
        class: class_name,
        loading: loading,
        decoding: 'async',
      )

      safe_join(sources)
    end
  end

  private

  # Check if the image is a Shrine upload
  def shrine_upload?(image)
    image.is_a?(Shrine::UploadedFile) || image.class.name.include?('UploadedFile')
  end

  # Generate picture tag for Shrine uploads using existing derivatives
  def picture_tag_for_shrine(image, alt:, sizes:, class_name:, loading:, model: nil)
    # Get derivatives from the model's attacher (preferred) or from the uploaded file data
    derivatives = get_shrine_derivatives(image, model: model)

    # Use Shrine's derivative system
    content_tag(:picture) do
      sources = []

      # WebP source if derivatives exist
      if derivatives && (derivatives[:card_webp] || derivatives[:medium_webp])
        webp_srcset = [
          derivatives[:card_webp] ? "#{derivatives[:card_webp].url} 150w" : nil,
          derivatives[:thumb_webp] ? "#{derivatives[:thumb_webp].url} 200w" : nil,
          derivatives[:medium_webp] ? "#{derivatives[:medium_webp].url} 600w" : nil,
          derivatives[:large_webp] ? "#{derivatives[:large_webp].url} 1000w" : nil,
        ].compact.join(', ')

        if webp_srcset.present?
          sources << tag.source(srcset: webp_srcset,
                                sizes: sizes,
                                type: 'image/webp',)
        end
      end

      # Original format source
      if derivatives
        original_srcset = [
          derivatives[:thumb] ? "#{derivatives[:thumb].url} 200w" : nil,
          derivatives[:medium] ? "#{derivatives[:medium].url} 600w" : nil,
          derivatives[:large] ? "#{derivatives[:large].url} 1000w" : nil,
        ].compact.join(', ')

        if original_srcset.present?
          sources << tag.source(srcset: original_srcset,
                                sizes: sizes,
                                type: image.mime_type,)
        end
      end

      # Fallback img tag
      fallback_url = if derivatives && derivatives[:medium]
                       derivatives[:medium].url
                     else
                       image.url
                     end

      sources << image_tag(
        fallback_url,
        alt: alt,
        class: class_name,
        loading: loading,
        decoding: 'async',
      )

      safe_join(sources)
    end
  end

  # Get derivatives from Shrine uploaded file
  # @param image [Shrine::UploadedFile] The uploaded file
  # @param model [ActiveRecord::Base, nil] The model that owns the image (e.g., Menuitem)
  def get_shrine_derivatives(image, model: nil)
    # Preferred path: use the model's attacher which has direct access to derivatives
    if model.respond_to?(:image_attacher)
      attacher_derivs = model.image_attacher.derivatives
      return attacher_derivs if attacher_derivs.present?
    end

    # Fallback: try accessing derivatives from the uploaded file's data hash
    if image.respond_to?(:[]) && image['derivatives']
      derivatives_data = image['derivatives']
      return nil unless derivatives_data.is_a?(Hash)

      derivatives = {}
      derivatives_data.each do |key, data|
        derivatives[key.to_sym] = Shrine.uploaded_file(data) if data
      end
      return derivatives if derivatives.present?
    end

    nil
  rescue StandardError => e
    Rails.logger.error "[ResponsiveImageHelper] Error accessing Shrine derivatives: #{e.message}"
    nil
  end

  # Generate optimized image tag with lazy loading
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @param alt [String] Alt text
  # @param class_name [String] CSS class
  # @param quality [Integer] Image quality
  # @return [String] HTML image tag
  def optimized_image_tag(image, alt:, class_name: '', quality: 85)
    return '' if image.blank?

    # Handle Shrine uploads - use medium derivative if available
    if shrine_upload?(image)
      derivatives = get_shrine_derivatives(image)
      src = derivatives && derivatives[:medium] ? derivatives[:medium].url : image.url
      return image_tag(
        src,
        alt: alt,
        class: class_name,
        loading: 'lazy',
        decoding: 'async',
      )
    end

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return '' if blob.blank?

    # Optimize compression
    optimized = ImageOptimizationService.optimize_compression(blob, quality: quality)
    src = url_for(optimized || blob)

    image_tag(
      src,
      alt: alt,
      class: class_name,
      loading: 'lazy',
      decoding: 'async',
    )
  end

  # Generate blur-up placeholder for lazy loading
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @param alt [String] Alt text
  # @param class_name [String] CSS class
  # @return [String] HTML with placeholder and full image
  def lazy_image_with_placeholder(image, alt:, class_name: '')
    return '' if image.blank?

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return '' if blob.blank?

    # Generate tiny placeholder (20px wide)
    placeholder = blob.variant(
      resize_to_limit: [20, nil],
      saver: { quality: 50 },
    ).processed

    placeholder_url = url_for(placeholder)
    full_url = url_for(blob)

    content_tag(:div, class: "lazy-image-container #{class_name}", data: { controller: 'lazy-image' }) do
      concat image_tag(placeholder_url,
                       alt: alt,
                       class: 'lazy-image-placeholder',
                       style: 'filter: blur(10px);',)
      concat image_tag(full_url,
                       alt: alt,
                       class: 'lazy-image-full',
                       loading: 'lazy',
                       data: { lazy_image_target: 'image' },)
    end
  end

  # Get image dimensions
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @return [Hash] Width and height
  def image_dimensions(image)
    return { width: 0, height: 0 } if image.blank?

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return { width: 0, height: 0 } if blob.blank?

    metadata = blob.metadata
    {
      width: metadata['width'] || 0,
      height: metadata['height'] || 0,
    }
  end

  # Calculate aspect ratio
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @return [Float] Aspect ratio (width / height)
  def image_aspect_ratio(image)
    dims = image_dimensions(image)
    return 1.0 if dims[:height].zero?

    dims[:width].to_f / dims[:height]
  end

  # Generate srcset for an image
  # @param image [ActiveStorage::Blob, ActiveStorage::Attachment] Image
  # @param sizes [Array<Integer>] Widths for srcset
  # @return [String] Srcset string
  def generate_srcset(image, sizes: [320, 640, 1024, 1920])
    return '' if image.blank?

    blob = image.is_a?(ActiveStorage::Attachment) ? image.blob : image
    return '' if blob.blank?

    variants = ImageOptimizationService.generate_responsive_variants(blob, sizes: sizes)

    variants.map do |width, variant|
      "#{url_for(variant)} #{width}w"
    end.join(', ')
  end
end
