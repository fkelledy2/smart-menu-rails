class MenuItemImageBatchJob
  include Sidekiq::Job

  private

  def update_progress(payload)
    Sidekiq.redis do |r|
      existing = {}
      begin
        json = r.get("image_gen:#{jid}")
        existing = json.present? ? JSON.parse(json) : {}
      rescue StandardError
        existing = {}
      end

      merged = existing.merge(payload.stringify_keys)
      r.setex("image_gen:#{jid}", 24 * 3600, merged.to_json)
    end
  rescue => e
    Rails.logger.warn("[MenuItemImageBatchJob] Failed to write progress for #{jid}: #{e.class}: #{e.message}")
  end

  def append_progress_log(message)
    Sidekiq.redis do |r|
      json = r.get("image_gen:#{jid}")
      payload = json.present? ? JSON.parse(json) : {}
      log = Array(payload['log'])
      log << { at: Time.current.iso8601, message: message }
      payload['log'] = log.last(50)
      r.setex("image_gen:#{jid}", 24 * 3600, payload.to_json)
    end
  rescue => e
    Rails.logger.warn("[MenuItemImageBatchJob] Failed to append progress log for #{jid}: #{e.class}: #{e.message}")
  end

  def set_progress(status, current, total, menu_id, message: nil, extra: nil)
    payload = {
      status: status,
      current: current,
      total: total,
      message: message || 'AI image generation in progress',
      menu_id: menu_id
    }.merge(extra.is_a?(Hash) ? extra : {})

    update_progress(payload)
    append_progress_log(payload[:message].to_s) if payload[:message].present?
  rescue => e
    Rails.logger.warn("[MenuItemImageBatchJob] Failed to set progress: #{e.message}")
  end

  public

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

    set_progress('running', 0, total, menu_id, message: 'Starting AI image generation')

    scope.find_each.with_index do |genimage, index|
      menuitem = genimage.menuitem
      item_name = menuitem&.name || 'Unknown'

      Rails.logger.info "[MenuItemImageBatchJob] [#{index + 1}/#{total}] Processing: '#{item_name}' (genimage ##{genimage.id})"

      # Skip if the genimage is associated with a wine item
      if menuitem&.itemtype == 'wine'
        Rails.logger.info "[MenuItemImageBatchJob] ⏭️  Skipped: '#{item_name}' (wine item)"
        skipped += 1
        set_progress('running', processed + skipped, total, menu_id, message: "Skipped '#{item_name}' (wine)")
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
        set_progress(
          'running',
          processed + skipped,
          total,
          menu_id,
          message: "Generated '#{item_name}' (#{processed + skipped}/#{total})",
          extra: {
            current_item_name: item_name,
            current_item_image_url: current_url
          }
        )
      rescue => e
        Rails.logger.warn("[MenuItemImageBatchJob] Progress update failed: #{e.message}")
      end

      # Small delay to avoid rate limiting (only if not the last item)
      sleep(1) if index < total - 1
    rescue StandardError => e
      errors += 1
      Rails.logger.error "[MenuItemImageBatchJob] ❌ Error processing '#{item_name}' (genimage ##{genimage.id}): #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
      set_progress('running', processed + skipped, total, menu_id, message: "Error on '#{item_name}': #{e.class}")
    end

    Rails.logger.info '=' * 80
    Rails.logger.info "[MenuItemImageBatchJob] 🎉 Finished AI image generation for #{menu_name}"
    Rails.logger.info "[MenuItemImageBatchJob] Summary: #{processed} generated, #{skipped} skipped, #{errors} errors (Total: #{total})"
    Rails.logger.info '=' * 80

    set_progress(
      'completed',
      processed + skipped,
      total,
      menu_id,
      message: 'Completed',
      extra: { summary: { processed: processed, skipped: skipped, errors: errors } }
    )
  end
end
