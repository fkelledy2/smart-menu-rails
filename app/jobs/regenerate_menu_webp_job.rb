class RegenerateMenuWebpJob
  include Sidekiq::Job

  def perform(menu_id)
    menu = Menu.find_by(id: menu_id)
    unless menu
      Rails.logger.error "[RegenerateMenuWebpJob] ❌ Menu #{menu_id} not found"
      return
    end

    Rails.logger.info "=" * 80
    Rails.logger.info "[RegenerateMenuWebpJob] 🖼️  Starting WebP regeneration for '#{menu.name}'"
    Rails.logger.info "=" * 80

    # Get all menu items with images for this menu
    menu_items = menu.menusections.flat_map(&:menuitems).select { |mi| mi.image.present? }
    total = menu_items.count
    
    Rails.logger.info "[RegenerateMenuWebpJob] Found #{total} menu items with images"
    
    processed = 0
    skipped = 0
    errors = 0

    menu_items.each.with_index do |menuitem, index|
      begin
        item_name = menuitem.name || "Unnamed Item"
        Rails.logger.info "[RegenerateMenuWebpJob] [#{index + 1}/#{total}] Processing: '#{item_name}' (menuitem ##{menuitem.id})"
        
        attacher = menuitem.image_attacher
        
        unless attacher&.file
          Rails.logger.info "[RegenerateMenuWebpJob] ⏭️  Skipped: '#{item_name}' (no image file)"
          skipped += 1
          next
        end

        # Check if WebP derivatives already exist
        has_webp = attacher.derivatives&.key?(:thumb_webp) &&
                   attacher.derivatives&.key?(:medium_webp) &&
                   attacher.derivatives&.key?(:large_webp)

        if has_webp
          Rails.logger.info "[RegenerateMenuWebpJob] ⏭️  Skipped: '#{item_name}' (WebP derivatives already exist)"
          skipped += 1
          next
        end

        # Generate derivatives (including WebP)
        Rails.logger.info "[RegenerateMenuWebpJob] 🔄 Generating WebP derivatives for '#{item_name}'..."
        
        start_time = Time.current
        attacher.create_derivatives
        attacher.atomic_persist
        duration = (Time.current - start_time).round(2)
        
        Rails.logger.info "[RegenerateMenuWebpJob] ✅ Generated WebP derivatives for '#{item_name}' (#{duration}s)"
        processed += 1
        
        # Log progress summary every 10 items
        if (index + 1) % 10 == 0
          Rails.logger.info "[RegenerateMenuWebpJob] 📊 Progress: #{index + 1}/#{total} (#{processed} processed, #{skipped} skipped, #{errors} errors)"
        end
        
      rescue StandardError => e
        errors += 1
        item_name = menuitem.name rescue "menuitem ##{menuitem.id}"
        Rails.logger.error "[RegenerateMenuWebpJob] ❌ Error processing '#{item_name}': #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
      end
    end

    Rails.logger.info "=" * 80
    Rails.logger.info "[RegenerateMenuWebpJob] 🎉 Finished WebP regeneration for '#{menu.name}'"
    Rails.logger.info "[RegenerateMenuWebpJob] Summary: #{processed} processed, #{skipped} skipped, #{errors} errors (Total: #{total})"
    Rails.logger.info "=" * 80
  end
end
