class ImageUploader < Shrine
  plugin :backgrounding
  plugin :derivatives
  plugin :processing
  plugin :validation_helpers
  plugin :store_dimensions
  plugin :determine_mime_type

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/webp]
    validate_max_size  10*1024*1024
  end

  Attacher.promote_block do
    GenerateImageDerivativesJob.perform_later(record.class.name, record.id)
  end

  Attacher.derivatives_processor do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    {
      thumb: magick.resize_to_limit!(200, 200),
      large: magick.resize_to_limit!(1000, 800)
    }
  end
end
