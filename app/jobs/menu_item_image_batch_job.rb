class MenuItemImageBatchJob
  include Sidekiq::Job

  def perform(menu_id)
    menu = Menu.find_by(id: menu_id)
    menu_name = menu&.name || "menu_id=#{menu_id}"

    Rails.logger.info '=' * 80
    Rails.logger.info "[MenuItemImageBatchJob] 🎨 Starting AI image generation for #{menu_name}"
    Rails.logger.info '=' * 80

    # Ensure there is a Genimage record per menuitem (seed missing ones)
    if menu
      begin
        created = 0
        menu.menuitems.includes(:menusection).find_each do |mi|
          next if mi.itemtype == 'wine' # we never generate for wines
          next if mi.genimage.present?
          Genimage.create!(
            restaurant: menu.restaurant,
            menu: menu,
            menusection: mi.menusection,
            menuitem: mi,
          )
          created += 1
        end
        Rails.logger.info "[MenuItemImageBatchJob] Seeded #{created} missing genimage records for menu #{menu.id}"
      rescue => e
        Rails.logger.warn "[MenuItemImageBatchJob] Failed seeding genimages for menu #{menu_id}: #{e.message}"
      end
    end

    # Prepare processing scope after seeding
    scope = Genimage.where(menu_id: menu_id)
    total = scope.count

    Rails.logger.info "[MenuItemImageBatchJob] Found #{total} genimage records to process"

    processed = 0
    skipped = 0
    errors = 0

    # Mark job as running in Redis
    begin
      Sidekiq.redis do |r|
        r.setex("image_gen:#{jid}", 24 * 3600, {
          status: 'running',
          current: 0,
          total: total,
          message: 'Starting AI image generation',
          menu_id: menu_id
        }.to_json)
      end
    rescue => e
      Rails.logger.warn("[MenuItemImageBatchJob] Failed to set running status: #{e.message}")
    end

    scope.find_each.with_index do |genimage, index|
      menuitem = genimage.menuitem
      item_name = menuitem&.name || 'Unknown'

      Rails.logger.info "[MenuItemImageBatchJob] [#{index + 1}/#{total}] Processing: '#{item_name}' (genimage ##{genimage.id})"

      # Skip if the genimage is associated with a wine item
      if menuitem&.itemtype == 'wine'
        Rails.logger.info "[MenuItemImageBatchJob] ⏭️  Skipped: '#{item_name}' (wine item)"
        skipped += 1
        # Update progress after skip
        begin
          Sidekiq.redis do |r|
            r.setex("image_gen:#{jid}", 24 * 3600, {
              status: 'running',
              current: processed + skipped,
              total: total,
              message: "Skipped '#{item_name}' (wine)",
              menu_id: menu_id
            }.to_json)
          end
        rescue => e
          Rails.logger.warn("[MenuItemImageBatchJob] Progress update failed: #{e.message}")
        end
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
      # Reload to ensure fresh attachment/derivatives are visible
      menuitem.reload
      Rails.logger.info "[MenuItemImageBatchJob] ✅ Generated AI image for '#{item_name}'"
      processed += 1

      # Update progress after each processed item
      begin
        # Compute a robust image URL with cache-busting
        current_url = menuitem&.webp_url(:medium) || menuitem&.medium_url || menuitem&.image_url
        Sidekiq.redis do |r|
          r.setex("image_gen:#{jid}", 24 * 3600, {
            status: 'running',
            current: processed + skipped,
            total: total,
            message: "Generated '#{item_name}' (#{processed + skipped}/#{total})",
            menu_id: menu_id,
            current_item_name: item_name,
            current_item_image_url: current_url
          }.to_json)
        end
      rescue => e
        Rails.logger.warn("[MenuItemImageBatchJob] Progress update failed: #{e.message}")
      end

      # Small delay to avoid rate limiting (only if not the last item)
      sleep(1) if index < total - 1
    rescue StandardError => e
      errors += 1
      Rails.logger.error "[MenuItemImageBatchJob] ❌ Error processing '#{item_name}' (genimage ##{genimage.id}): #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
      # Update error progress
      begin
        Sidekiq.redis do |r|
          r.setex("image_gen:#{jid}", 24 * 3600, {
            status: 'running',
            current: processed + skipped,
            total: total,
            message: "Error on '#{item_name}'",
            menu_id: menu_id
          }.to_json)
        end
      rescue => e2
        Rails.logger.warn("[MenuItemImageBatchJob] Progress update failed: #{e2.message}")
      end
    end

    Rails.logger.info '=' * 80
    Rails.logger.info "[MenuItemImageBatchJob] 🎉 Finished AI image generation for #{menu_name}"
    Rails.logger.info "[MenuItemImageBatchJob] Summary: #{processed} generated, #{skipped} skipped, #{errors} errors (Total: #{total})"
    Rails.logger.info '=' * 80

    # Mark job as completed
    begin
      Sidekiq.redis do |r|
        r.setex("image_gen:#{jid}", 24 * 3600, {
          status: 'completed',
          current: processed + skipped,
          total: total,
          message: 'Completed',
          menu_id: menu_id,
          summary: { processed: processed, skipped: skipped, errors: errors }
        }.to_json)
      end
    rescue => e
      Rails.logger.warn("[MenuItemImageBatchJob] Failed to mark completion: #{e.message}")
    end
  end
end
