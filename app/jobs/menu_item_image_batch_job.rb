class MenuItemImageBatchJob
  include Sidekiq::Job

  def perform(menu_id)
    menu = Menu.find_by(id: menu_id)
    menu_name = menu&.name || "menu_id=#{menu_id}"
    
    Rails.logger.info "=" * 80
    Rails.logger.info "[MenuItemImageBatchJob] 🎨 Starting AI image generation for #{menu_name}"
    Rails.logger.info "=" * 80
    
    # Call the rake task logic directly
    scope = Genimage.where(menu_id: menu_id)
    total = scope.count
    
    Rails.logger.info "[MenuItemImageBatchJob] Found #{total} genimage records to process"
    
    processed = 0
    skipped = 0
    errors = 0
    
    scope.find_each.with_index do |genimage, index|
      menuitem = genimage.menuitem
      item_name = menuitem&.name || "Unknown"
      
      Rails.logger.info "[MenuItemImageBatchJob] [#{index + 1}/#{total}] Processing: '#{item_name}' (genimage ##{genimage.id})"

      # Skip if the genimage is associated with a wine item
      if menuitem&.itemtype == 'wine'
        Rails.logger.info "[MenuItemImageBatchJob] ⏭️  Skipped: '#{item_name}' (wine item)"
        skipped += 1
        next
      end
      
      unless menuitem
        Rails.logger.warn "[MenuItemImageBatchJob] ⚠️  Skipped: genimage ##{genimage.id} (no associated menuitem)"
        skipped += 1
        next
      end

      # Process the image using the job (synchronously within this job)
      Rails.logger.info "[MenuItemImageBatchJob] 🖼️  Generating AI image for '#{item_name}'..."
      MenuItemImageGeneratorJob.perform_sync(genimage.id)
      Rails.logger.info "[MenuItemImageBatchJob] ✅ Generated AI image for '#{item_name}'"
      processed += 1

      # Small delay to avoid rate limiting (only if not the last item)
      sleep(1) if index < total - 1
    rescue StandardError => e
      errors += 1
      Rails.logger.error "[MenuItemImageBatchJob] ❌ Error processing '#{item_name}' (genimage ##{genimage.id}): #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
    end

    Rails.logger.info "=" * 80
    Rails.logger.info "[MenuItemImageBatchJob] 🎉 Finished AI image generation for #{menu_name}"
    Rails.logger.info "[MenuItemImageBatchJob] Summary: #{processed} generated, #{skipped} skipped, #{errors} errors (Total: #{total})"
    Rails.logger.info "=" * 80
  end
end
