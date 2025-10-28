# frozen_string_literal: true

namespace :images do
  desc 'Convert existing menu item images to WebP format by regenerating derivatives'
  task convert_to_webp: :environment do
    puts '🖼️  Starting WebP conversion for existing menu item images...'
    puts '=' * 80

    total = Menuitem.where.not(image_data: nil).count
    processed = 0
    successful = 0
    failed = 0
    skipped = 0

    puts "Found #{total} menu items with images"
    puts 'This will regenerate derivatives including WebP versions...'
    puts ''

    Menuitem.where.not(image_data: nil).find_each.with_index do |menuitem, index|
      begin
        progress = ((index + 1).to_f / total * 100).round(1)
        print "\r[#{index + 1}/#{total}] (#{progress}%) Converting Menuitem #{menuitem.id}: #{menuitem.name.truncate(40)}"

        if menuitem.image.present?
          # Regenerate derivatives (this will create WebP versions)
          attacher = menuitem.image_attacher

          if attacher&.file
            # Create derivatives using the uploader's derivative processor
            derivatives = attacher.create_derivatives

            # Store the derivatives
            attacher.merge_derivatives(derivatives)
            attacher.atomic_persist

            successful += 1
            print ' ✅'
          else
            failed += 1
            print ' ⚠️ '
          end
        else
          skipped += 1
          print ' ⏭️ '
        end

        processed += 1
      rescue StandardError => e
        failed += 1
        puts "\n  ❌ Error: #{e.message}"
        Rails.logger.error "[WebP Conversion] Error converting Menuitem #{menuitem.id}: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end

      # Small delay to avoid overwhelming the system
      sleep(0.1) if ((index + 1) % 10).zero?
    end

    puts "\n"
    puts '=' * 80
    puts '✅ Conversion complete!'
    puts ''
    puts 'Summary:'
    puts "  Total processed:  #{processed}/#{total}"
    puts "  Successful:       #{successful} (#{(successful.to_f / total * 100).round(1)}%)"
    puts "  Failed:           #{failed}"
    puts "  Skipped:          #{skipped}"
    puts ''
    puts 'WebP images are now available for converted menu items!'
    puts 'Check with: Menuitem.find(ID).has_webp_derivatives?'
  end

  desc 'Regenerate all menu item images with WebP optimization'
  task regenerate_with_webp: :environment do
    puts '🔄 Starting image regeneration with WebP optimization...'
    puts '=' * 80

    total_menus = Menu.count
    processed = 0

    puts "Found #{total_menus} menus"
    puts ''

    Menu.find_each do |menu|
      items_count = menu.menusections.joins(:menuitems).count

      puts "[#{processed + 1}/#{total_menus}] Queuing menu: #{menu.name} (#{items_count} items)"

      MenuItemImageBatchJob.perform_async(menu.id)
      processed += 1

      # Avoid overwhelming the queue
      sleep(2)
    end

    puts ''
    puts '=' * 80
    puts "✅ All #{total_menus} menus queued for image regeneration"
    puts ''
    puts 'Images will be regenerated in the background with WebP optimization.'
    puts 'Check Sidekiq dashboard for progress.'
  end

  desc 'Show WebP conversion statistics'
  task webp_stats: :environment do
    puts '📊 WebP Conversion Statistics'
    puts '=' * 80

    total_items = Menuitem.where.not(image_data: nil).count

    # This is a simplified check - in production you'd want to check actual variants
    puts "Total menu items with images: #{total_items}"
    puts ''
    puts "Note: Run 'rake images:convert_to_webp' to convert existing images"
    puts "      or 'rake images:regenerate_with_webp' to regenerate all images"
  end
end
