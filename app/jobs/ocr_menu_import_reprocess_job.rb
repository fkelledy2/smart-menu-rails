class OcrMenuImportReprocessJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 2

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

  public

  def perform(ocr_menu_import_id, dry_run = false)
    import = OcrMenuImport.includes(:restaurant, :menu).find_by(id: ocr_menu_import_id)
    return unless import

    unless import.completed?
      Rails.logger.warn("[OcrMenuImportReprocessJob] import ##{import.id} not completed; skipping")
      return
    end

    unless import.menu_id.present? && import.menu
      Rails.logger.warn("[OcrMenuImportReprocessJob] import ##{import.id} has no menu; skipping")
      return
    end

    restaurant = import.restaurant
    menu = import.menu

    ocr_items_total = import.ocr_menu_items.count
    ocr_items_confirmed = import.ocr_menu_items.where(is_confirmed: true).count rescue nil
    ocr_sections_total = import.ocr_menu_sections.count
    ocr_sections_confirmed = import.ocr_menu_sections.where(is_confirmed: true).count rescue nil
    menuitems_total = menu.menuitems.count

    log_event(
      'ocr_import.reprocess.start',
      import_id: import.id,
      restaurant_id: restaurant.id,
      menu_id: menu.id,
      dry_run: dry_run,
      ocr_sections_total: ocr_sections_total,
      ocr_sections_confirmed: ocr_sections_confirmed,
      ocr_items_total: ocr_items_total,
      ocr_items_confirmed: ocr_items_confirmed,
      menuitems_total: menuitems_total,
    )

    if dry_run
      return
    end

    # 1) OCR AI Polish (updates OCR menu items only; does not touch allergens)
    begin
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      log_event('ocr_import.reprocess.polish.start', import_id: import.id, menu_id: menu.id)
      OcrMenuImportPolisherJob.new.perform(import.id)
      dt = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
      log_event('ocr_import.reprocess.polish.completed', import_id: import.id, menu_id: menu.id, duration_s: dt.round(3))
    rescue StandardError => e
      log_event('ocr_import.reprocess.polish.failed', import_id: import.id, menu_id: menu.id, error_class: e.class.name, error: e.message)
    end

    # 2) Republish/upsert into menu (copies name/description/image_prompt and maps allergens from OCR-only)
    begin
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      log_event('ocr_import.reprocess.upsert.start', import_id: import.id, menu_id: menu.id)
      _menu, stats = ImportToMenu.new(restaurant: restaurant, import: import).upsert_into_menu(menu, sync: false)
      dt = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
      log_event('ocr_import.reprocess.upsert.completed', import_id: import.id, menu_id: menu.id, duration_s: dt.round(3), stats: stats)
    rescue StandardError => e
      log_event('ocr_import.reprocess.upsert.failed', import_id: import.id, menu_id: menu.id, error_class: e.class.name, error: e.message)
      raise
    end

    # 3) Context-based image regeneration (only items whose prompt fingerprint changed)
    begin
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      genimages_total = Genimage.where(menu_id: menu.id).count
      log_event('ocr_import.reprocess.image_regen.enqueue', import_id: import.id, menu_id: menu.id, genimages_total: genimages_total)
      regen_jid = MenuItemImageContextBatchJob.perform_async(menu.id)
      dt = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
      log_event('ocr_import.reprocess.image_regen.enqueued', import_id: import.id, menu_id: menu.id, enqueued_jid: regen_jid, duration_s: dt.round(3))
    rescue StandardError => e
      log_event('ocr_import.reprocess.image_regen.failed', import_id: import.id, menu_id: menu.id, error_class: e.class.name, error: e.message)
    end

    log_event('ocr_import.reprocess.completed', import_id: import.id, restaurant_id: restaurant.id, menu_id: menu.id)
  end
end
