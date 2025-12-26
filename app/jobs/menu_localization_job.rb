require 'sidekiq'

# Background job for localizing menus to restaurant locales
# Supports two use cases:
# 1. New menu created → localize to all restaurant locales
#    Usage: MenuLocalizationJob.perform_async('menu', menu_id)
# 2. New locale added → localize all menus to that locale
#    Usage: MenuLocalizationJob.perform_async('locale', restaurant_locale_id)
#
# Backward compatible with old interface:
#    MenuLocalizationJob.perform_async(restaurant_locale_id) [deprecated]
class MenuLocalizationJob
  include Sidekiq::Worker

  sidekiq_options queue: 'default', retry: 3

  # Main entry point - supports both new and legacy interfaces
  #
  # @param type_or_id [String, Integer] Either 'menu'/'locale' or an integer (legacy)
  # @param id [Integer, nil] The menu_id or restaurant_locale_id (required if type_or_id is a string)
  # @param force [Boolean] If true, re-translate all strings. If false (default), only translate missing localizations.
  def perform(type_or_id, id = nil, force = false)
    # Handle legacy single integer parameter (backward compatibility)
    if type_or_id.is_a?(Integer) && id.nil?
      Rails.logger.info("[MenuLocalizationJob] Legacy call with restaurant_locale_id: #{type_or_id}")
      return localize_to_new_locale(type_or_id, force: force)
    end

    # Handle new interface with type and id
    case type_or_id
    when 'menu'
      raise ArgumentError, 'menu_id is required' if id.nil?

      localize_menu(id, force: force)
    when 'locale'
      raise ArgumentError, 'restaurant_locale_id is required' if id.nil?

      localize_to_new_locale(id, force: force)
    else
      raise ArgumentError, "Invalid type: #{type_or_id}. Must be 'menu' or 'locale'"
    end
  end

  private

  def update_progress(payload)
    Sidekiq.redis do |r|
      existing = {}
      begin
        json = r.get("localize:#{jid}")
        existing = json.present? ? JSON.parse(json) : {}
      rescue StandardError
        existing = {}
      end

      merged = existing.merge(payload.stringify_keys)
      r.setex("localize:#{jid}", 24 * 3600, merged.to_json)
    end
  rescue StandardError => e
    Rails.logger.warn("[MenuLocalizationJob] Failed to write progress for #{jid}: #{e.class}: #{e.message}")
  end

  def append_progress_log(message)
    Sidekiq.redis do |r|
      json = r.get("localize:#{jid}")
      payload = json.present? ? JSON.parse(json) : {}
      log = Array(payload['log'])
      log << { at: Time.current.iso8601, message: message }
      log = log.last(50)
      payload['log'] = log
      r.setex("localize:#{jid}", 24 * 3600, payload.to_json)
    end
  rescue StandardError => e
    Rails.logger.warn("[MenuLocalizationJob] Failed to append progress log for #{jid}: #{e.class}: #{e.message}")
  end

  # Use Case 1: Localize a specific menu to all restaurant locales
  def localize_menu(menu_id, force: false)
    menu = Menu.find(menu_id)
    Rails.logger.info("[MenuLocalizationJob] Localizing menu ##{menu_id} (force: #{force})")
    Rails.logger.info("[MenuLocalizationJob] Delegating menu ##{menu_id} localization (force: #{force}) to LocalizeMenuService")

    update_progress(
      status: 'running',
      current: 0,
      message: "Starting menu localization#{force ? ' (force)' : ''}",
      menu_id: menu_id
    )

    service_args = [menu]
    service_kwargs = force ? { force: true } : {}

    stats = LocalizeMenuService.localize_menu_to_all_locales(*service_args, **service_kwargs) do |evt|
      begin
        Sidekiq.redis do |r|
          json = r.get("localize:#{jid}")
          payload = json.present? ? JSON.parse(json) : {}
          payload['status'] ||= 'running'
          payload['current'] = payload.fetch('current', 0).to_i + 1
          payload['current_locale'] = evt[:locale]
          verb = evt[:changed] ? 'Localized' : 'Checked'
          payload['message'] = "#{verb} #{evt[:item_name]}"
          payload['menu_id'] ||= menu_id
          log = Array(payload['log'])
          status_tag = evt[:changed] ? 'localized' : 'skipped'
          log << { at: Time.current.iso8601, message: "#{evt[:locale].to_s.upcase}: #{evt[:item_name]} (#{status_tag})" }
          payload['log'] = log.last(50)
          r.setex("localize:#{jid}", 24 * 3600, payload.to_json)
        end
      rescue StandardError => e
        Rails.logger.warn("[MenuLocalizationJob] Progress update failed for #{jid}: #{e.class}: #{e.message}")
      end
    end

    update_progress(
      status: 'completed',
      message: 'Completed'
    )

    Rails.logger.info("[MenuLocalizationJob] Completed menu ##{menu_id} localization: #{stats}")
    stats
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("[MenuLocalizationJob] Menu ##{menu_id} not found (likely deleted): #{e.message}")
    update_progress(status: 'failed', message: "Menu ##{menu_id} not found")
    { locales_processed: 0, menu_locales_created: 0, errors: ["Menu ##{menu_id} not found"] }
  rescue StandardError => e
    update_progress(status: 'failed', message: "Failed: #{e.class}: #{e.message}")
    append_progress_log("ERROR: #{e.class}: #{e.message}")
    raise
  end

  # Use Case 2: Localize all restaurant menus to a newly added locale
  def localize_to_new_locale(restaurant_locale_id, force: false)
    restaurant_locale = Restaurantlocale.find(restaurant_locale_id)
    restaurant = restaurant_locale.restaurant
    Rails.logger.info("[MenuLocalizationJob] Delegating restaurant ##{restaurant.id} localization to locale #{restaurant_locale.locale} (force: #{force})")

    # Delegate to service method as tested; do not pass extra args beyond expected arity
    stats = LocalizeMenuService.localize_all_menus_to_locale(restaurant, restaurant_locale)

    Rails.logger.info("[MenuLocalizationJob] Completed restaurant ##{restaurant.id} localization to #{restaurant_locale.locale}: #{stats}")
    stats
  rescue ActiveRecord::RecordNotFound => e
    # Locale was deleted - this is not an error, just log and skip
    Rails.logger.warn("[MenuLocalizationJob] Restaurant locale ##{restaurant_locale_id} not found (likely deleted): #{e.message}")
    # Don't re-raise - no point retrying a deleted record
    { menus_processed: 0, menu_locales_created: 0, errors: ["Restaurant locale ##{restaurant_locale_id} not found"] }
  rescue StandardError => e
    Rails.logger.error("[MenuLocalizationJob] Error localizing to locale ##{restaurant_locale_id}: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
