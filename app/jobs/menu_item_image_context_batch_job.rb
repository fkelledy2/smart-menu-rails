class MenuItemImageContextBatchJob
  include Sidekiq::Job

  # Use default queue; generation itself uses the limited queue
  sidekiq_options queue: 'default', retry: 3

  private

  def log_event(event, payload = {})
    base = {
      event: event,
      job: self.class.name,
      jid: jid,
    }
    Rails.logger.info(base.merge(payload).to_json)
  rescue StandardError
    Rails.logger.info("[#{self.class.name}] #{event} #{payload.inspect}")
  end

  def update_progress(payload)
    Sidekiq.redis do |r|
      existing = {}
      begin
        json = r.get("image_ctx_gen:#{jid}")
        existing = json.present? ? JSON.parse(json) : {}
      rescue StandardError
        existing = {}
      end

      merged = existing.merge(payload.stringify_keys)
      r.setex("image_ctx_gen:#{jid}", 24 * 3600, merged.to_json)
    end
  rescue StandardError => e
    Rails.logger.warn("[MenuItemImageContextBatchJob] Failed to write progress for #{jid}: #{e.class}: #{e.message}")
  end

  def set_progress(status, current, total, menu_id, message: nil, extra: nil)
    payload = {
      status: status,
      current: current,
      total: total,
      message: message || 'AI image regeneration (context-based) in progress',
      menu_id: menu_id,
    }.merge(extra.is_a?(Hash) ? extra : {})

    update_progress(payload)
  rescue StandardError => e
    Rails.logger.warn("[MenuItemImageContextBatchJob] Failed to set progress: #{e.message}")
  end

  def ensure_genimages_for_menu!(menu)
    created = 0
    menu.menuitems.includes(:menusection).find_each do |mi|
      next if mi.itemtype == 'wine'
      next if mi.genimage.present?

      Genimage.create!(
        restaurant: menu.restaurant,
        menu: menu,
        menusection: mi.menusection,
        menuitem: mi,
      )
      created += 1
    end
    created
  end

  public

  def perform(menu_id)
    menu = Menu.find_by(id: menu_id)
    return unless menu

    menu_name = menu.name.to_s
    restaurant_id = menu.restaurant_id
    log_event('menu_image_context_regen.start', menu_id: menu.id, restaurant_id: restaurant_id, menu_name: menu_name)

    begin
      created = ensure_genimages_for_menu!(menu)
      log_event('menu_image_context_regen.seed_genimages', menu_id: menu.id, created: created)
    rescue StandardError => e
      log_event('menu_image_context_regen.seed_genimages_failed', menu_id: menu.id, error_class: e.class.name, error: e.message)
    end

    scope = Genimage.where(menu_id: menu_id)
    total = scope.count

    processed = 0
    skipped = 0
    regenerated = 0
    errors = 0

    set_progress('running', 0, total, menu_id, message: 'Computing image context fingerprints')
    log_event('menu_image_context_regen.scope', menu_id: menu.id, genimages_total: total)

    scope.find_each.with_index do |genimage, index|
      menuitem = genimage.menuitem
      item_name = menuitem&.name || 'Unknown'

      if menuitem&.itemtype == 'wine'
        skipped += 1
        processed += 1
        next
      end

      unless menuitem
        skipped += 1
        processed += 1
        next
      end

      begin
        _prompt, fingerprint = MenuItemImageGeneratorJob.build_prompt_and_fingerprint(genimage)
        existing_fp = genimage.respond_to?(:prompt_fingerprint) ? genimage.prompt_fingerprint.to_s : ''

        if existing_fp.to_s.strip == '' || existing_fp != fingerprint
          regenerated += 1
          log_event(
            'menu_image_context_regen.regenerate',
            menu_id: menu.id,
            genimage_id: genimage.id,
            menuitem_id: menuitem.id,
            item_name: item_name,
            from_fp: existing_fp.to_s[0, 12],
            to_fp: fingerprint.to_s[0, 12],
          )
          set_progress('running', processed, total, menu_id, message: "Regenerating '#{item_name}' (context changed)")
          MenuItemImageGeneratorJob.perform_sync(genimage.id)
        end
      rescue StandardError => e
        errors += 1
        log_event(
          'menu_image_context_regen.error',
          menu_id: menu.id,
          genimage_id: genimage.id,
          menuitem_id: menuitem&.id,
          item_name: item_name,
          error_class: e.class.name,
          error: e.message,
        )
      ensure
        processed += 1
        if (index % 20).zero?
          log_event(
            'menu_image_context_regen.progress',
            menu_id: menu.id,
            processed: processed,
            total: total,
            regenerated: regenerated,
            skipped: skipped,
            errors: errors,
          )
          set_progress(
            'running',
            processed,
            total,
            menu_id,
            message: "Checked #{processed}/#{total}",
            extra: { regenerated: regenerated, skipped: skipped, errors: errors },
          )
        end
      end
    end

    set_progress(
      'completed',
      processed,
      total,
      menu_id,
      message: 'Completed',
      extra: { regenerated: regenerated, skipped: skipped, errors: errors },
    )

    log_event(
      'menu_image_context_regen.completed',
      menu_id: menu.id,
      restaurant_id: restaurant_id,
      processed: processed,
      total: total,
      regenerated: regenerated,
      skipped: skipped,
      errors: errors,
    )
  end
end
