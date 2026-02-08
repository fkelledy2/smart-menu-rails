namespace :shrine do
  desc 'Promote cached image attachments to store'
  task promote_cached_images: :environment do
    dry_run = ENV.fetch('DRY_RUN', '1') != '0'
    clear_missing = ENV.fetch('CLEAR_MISSING', '0') == '1'
    limit = ENV['LIMIT']&.to_i
    batch_size = ENV.fetch('BATCH_SIZE', '200').to_i

    model_names = if ENV['MODELS'].present?
                    ENV['MODELS'].split(',').map(&:strip).compact_blank
                  else
                    %w[Menuitem Menusection Menu Restaurant]
                  end

    checked = 0
    candidates = 0
    promoted = 0
    missing = 0
    cleared = 0
    errors = 0

    model_names.each do |model_name|
      model = model_name.safe_constantize
      next unless model
      next unless model.column_names.include?('image_data')

      scope = model.where.not(image_data: [nil, ''])
      scope = scope.limit(limit) if limit

      scope.find_each(batch_size: batch_size) do |record|
        checked += 1

        image = record.image
        next unless image
        next unless image.storage_key.to_s == 'cache'

        candidates += 1

        if dry_run
          puts "[DRY_RUN] #{model_name}##{record.id} image_id=#{image.id} storage=#{image.storage_key}"
          next
        end

        begin
          record.image_attacher.atomic_promote
          promoted += 1
          puts "[PROMOTED] #{model_name}##{record.id} image_id=#{image.id}"
        rescue StandardError => e
          if e.class.name.include?('FileNotFound') || e.is_a?(Errno::ENOENT)
            missing += 1
            puts "[MISSING] #{model_name}##{record.id} image_id=#{image.id} error=#{e.class}: #{e.message}"

            if clear_missing
              record.update(image: nil)
              cleared += 1
              puts "[CLEARED] #{model_name}##{record.id}"
            end
          else
            errors += 1
            puts "[ERROR] #{model_name}##{record.id} image_id=#{image.id} error=#{e.class}: #{e.message}"
          end
        end
      end
    end

    puts "checked=#{checked} candidates=#{candidates} promoted=#{promoted} missing=#{missing} cleared=#{cleared} errors=#{errors} dry_run=#{dry_run}"
  end
end
