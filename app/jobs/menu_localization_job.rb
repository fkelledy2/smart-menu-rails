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

  # Use Case 1: Localize a specific menu to all restaurant locales
  def localize_menu(menu_id, force: false)
    menu = Menu.find(menu_id)
    restaurant = menu.restaurant
    locales = restaurant.restaurantlocales.active.to_a
    items_count = menu.menuitems.count
    total = locales.size * items_count

    Rails.logger.info("[MenuLocalizationJob] Localizing menu ##{menu_id} to #{total} restaurant locales (force: #{force})")

    current = 0
    aggregate = { locales_processed: 0, menu_locales_created: 0, menu_locales_updated: 0,
                  section_locales_created: 0, section_locales_updated: 0,
                  item_locales_created: 0, item_locales_updated: 0, rate_limited_items: [], errors: [], }

    # Mark as running with 0 progress so UIs move past 'queued'
    begin
      Sidekiq.redis do |r|
        r.setex("localize:#{jid}", 24 * 3600, {
          status: 'running',
          current: current,
          total: total,
          message: 'Starting menu localization',
          menu_id: menu_id
        }.to_json)
      end
    rescue => e
      Rails.logger.warn("[MenuLocalizationJob] Failed to set running status: #{e.message}")
    end

    locales.each do |restaurant_locale|
      begin
        locale_code = restaurant_locale.locale
        # Pass a per-item callback to publish progress for every translated item
        stats = LocalizeMenuService.localize_menu_to_locale(menu, restaurant_locale, force: force) do |info|
          begin
            current += 1
            Sidekiq.redis do |r|
              r.setex("localize:#{jid}", 24 * 3600, {
                status: 'running',
                current: current,
                total: total,
                message: "Translated '#{info[:item_name]}' → '#{info[:translated_name]}' (#{locale_code.upcase})",
                menu_id: menu_id,
                current_locale: locale_code
              }.to_json)
            end
          rescue => e
            Rails.logger.warn("[MenuLocalizationJob] Item progress update failed: #{e.message}")
          end
        end
        aggregate[:locales_processed] += 1
        aggregate[:menu_locales_created] += stats[:menu_locales_created]
        aggregate[:menu_locales_updated] += stats[:menu_locales_updated]
        aggregate[:section_locales_created] += stats[:section_locales_created]
        aggregate[:section_locales_updated] += stats[:section_locales_updated]
        aggregate[:item_locales_created] += stats[:item_locales_created]
        aggregate[:item_locales_updated] += stats[:item_locales_updated]
        aggregate[:rate_limited_items].concat(stats[:rate_limited_items]) if stats[:rate_limited_items]
        # If no items were changed (force false), still emit a locale-level heartbeat (no increment)
        if stats[:item_locales_created].to_i + stats[:item_locales_updated].to_i == 0
          begin
            Sidekiq.redis do |r|
              r.setex("localize:#{jid}", 24 * 3600, {
                status: 'running',
                current: current,
                total: total,
                message: "Checked locale #{locale_code.upcase} (nothing to translate)",
                menu_id: menu_id,
                current_locale: locale_code
              }.to_json)
            end
          rescue => e
            Rails.logger.warn("[MenuLocalizationJob] Locale heartbeat update failed: #{e.message}")
          end
        end
      rescue StandardError => e
        err = "Failed to localize menu ##{menu_id} to #{restaurant_locale.locale}: #{e.message}"
        Rails.logger.error("[MenuLocalizationJob] #{err}")
        aggregate[:errors] << err
      end
    end

    # Queue rate-limited items for retry
    if aggregate[:rate_limited_items].any?
      Rails.logger.info("[MenuLocalizationJob] Queueing #{aggregate[:rate_limited_items].count} rate-limited items for retry")
      MenuLocalizationRetryJob.perform_in(5.minutes, aggregate[:rate_limited_items])
    end

    Rails.logger.info("[MenuLocalizationJob] Completed menu ##{menu_id} localization: #{aggregate}")

    # Mark as completed
    begin
      Sidekiq.redis do |r|
        r.setex("localize:#{jid}", 24 * 3600, {
          status: 'completed',
          current: total,
          total: total,
          message: 'Completed',
          menu_id: menu_id,
          summary: aggregate
        }.to_json)
      end
    rescue => e
      Rails.logger.warn("[MenuLocalizationJob] Failed to mark completion: #{e.message}")
    end

    aggregate
  rescue ActiveRecord::RecordNotFound => e
    # Menu was deleted - this is not an error, just log and skip
    Rails.logger.warn("[MenuLocalizationJob] Menu ##{menu_id} not found (likely deleted): #{e.message}")
    # Don't re-raise - no point retrying a deleted record
    { locales_processed: 0, menu_locales_created: 0, errors: ["Menu ##{menu_id} not found"] }
  rescue StandardError => e
    Rails.logger.error("[MenuLocalizationJob] Error localizing menu ##{menu_id}: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  # Use Case 2: Localize all restaurant menus to a newly added locale
  def localize_to_new_locale(restaurant_locale_id, force: false)
    restaurant_locale = Restaurantlocale.find(restaurant_locale_id)
    restaurant = restaurant_locale.restaurant
    Rails.logger.info("[MenuLocalizationJob] Localizing all menus for restaurant ##{restaurant.id} to locale #{restaurant_locale.locale} (force: #{force})")

    stats = LocalizeMenuService.localize_all_menus_to_locale(restaurant, restaurant_locale, force: force)

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
