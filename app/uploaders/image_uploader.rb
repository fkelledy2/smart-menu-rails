class ImageUploader < Shrine
  plugin :backgrounding
  plugin :derivatives
  plugin :validation_helpers
  plugin :store_dimensions
  plugin :determine_mime_type

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/webp]
    validate_max_size  10 * 1024 * 1024
  end

  Attacher.promote_block do |attacher|
    GenerateImageDerivativesJob.perform_later(attacher.record.class.name, attacher.record.id)
  end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)

    # Original format derivatives (PNG/JPEG)
    derivatives = {
      thumb: magick.resize_to_limit!(200, 200),
      medium: magick.resize_to_limit!(600, 480),
      large: magick.resize_to_limit!(1000, 800),
    }

    # WebP derivatives for better performance
    derivatives.merge!({
      thumb_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 85)
        .resize_to_limit!(200, 200),
      medium_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 85)
        .resize_to_limit!(600, 480),
      large_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 85)
        .resize_to_limit!(1000, 800),
    })

    derivatives
  end
end
