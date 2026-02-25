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
    next unless attacher.file

    attacher.atomic_promote
    GenerateImageDerivativesJob.perform_later(attacher.record.class.name, attacher.record.id)
  end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)

    # Original format derivatives (PNG/JPEG)
    derivatives = {
      thumb: magick.resize_to_limit!(200, 200),
      medium: ImageProcessing::MiniMagick.source(original).resize_to_limit!(600, 480),
      large: ImageProcessing::MiniMagick.source(original).resize_to_limit!(1000, 800),
    }

    # WebP derivatives — optimised for customer-facing smartmenu performance.
    # card_webp (150px, q70): mobile card thumbnails in the horizontal layout
    # thumb_webp (200px, q75): small thumbnails
    # medium_webp (600px, q75): modal "add to order" popup and tablet card view
    # large_webp (1000px, q80): full-screen / desktop hero images
    # LQIP — 20px wide, q20, WebP. Tiny enough to inline as base64 data URI
    # for instant blur-up placeholder on customer smartmenu pages.
    derivatives[:lqip] = ImageProcessing::MiniMagick
      .source(original)
      .convert('webp')
      .saver(quality: 20)
      .resize_to_limit!(20, 20)

    derivatives.merge!({
      card_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 70)
        .resize_to_limit!(150, 150),
      thumb_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 75)
        .resize_to_limit!(200, 200),
      medium_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 75)
        .resize_to_limit!(600, 480),
      large_webp: ImageProcessing::MiniMagick
        .source(original)
        .convert('webp')
        .saver(quality: 80)
        .resize_to_limit!(1000, 800),
    })

    derivatives
  end
end
