# Service for localizing menus, sections, and items to restaurant locales
# Supports two primary use cases:
# 1. New menu created → localize to all restaurant locales
# 2. New locale added → localize all menus to that locale
class LocalizeMenuService
  class << self
    # Use Case 1: Localize a single menu to all active restaurant locales
    # Called when a new menu is created (via OCR import or manual creation)
    #
    # @param menu [Menu] The menu to localize
    # @return [Hash] Statistics about localization operations
    def localize_menu_to_all_locales(menu)
      restaurant = menu.restaurant
      stats = { locales_processed: 0, menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0, errors: [] }

      restaurant.restaurantlocales.active.find_each do |restaurant_locale|
        begin
          locale_stats = localize_menu_to_locale(menu, restaurant_locale)
          stats[:locales_processed] += 1
          stats[:menu_locales_created] += locale_stats[:menu_locales_created]
          stats[:menu_locales_updated] += locale_stats[:menu_locales_updated]
          stats[:section_locales_created] += locale_stats[:section_locales_created]
          stats[:section_locales_updated] += locale_stats[:section_locales_updated]
          stats[:item_locales_created] += locale_stats[:item_locales_created]
          stats[:item_locales_updated] += locale_stats[:item_locales_updated]
        rescue StandardError => e
          error_msg = "Failed to localize menu ##{menu.id} to locale #{restaurant_locale.locale}: #{e.message}"
          Rails.logger.error("[LocalizeMenuService] #{error_msg}")
          stats[:errors] << error_msg
        end
      end

      Rails.logger.info("[LocalizeMenuService] Localized menu ##{menu.id} to #{stats[:locales_processed]} locales")
      stats
    end

    # Use Case 2: Localize all restaurant menus to a newly added locale
    # Called when a new restaurant locale is created
    #
    # @param restaurant [Restaurant] The restaurant whose menus to localize
    # @param restaurant_locale [Restaurantlocale] The new locale to localize to
    # @return [Hash] Statistics about localization operations
    def localize_all_menus_to_locale(restaurant, restaurant_locale)
      stats = { menus_processed: 0, menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0, errors: [] }

      restaurant.menus.find_each do |menu|
        begin
          menu_stats = localize_menu_to_locale(menu, restaurant_locale)
          stats[:menus_processed] += 1
          stats[:menu_locales_created] += menu_stats[:menu_locales_created]
          stats[:menu_locales_updated] += menu_stats[:menu_locales_updated]
          stats[:section_locales_created] += menu_stats[:section_locales_created]
          stats[:section_locales_updated] += menu_stats[:section_locales_updated]
          stats[:item_locales_created] += menu_stats[:item_locales_created]
          stats[:item_locales_updated] += menu_stats[:item_locales_updated]
        rescue StandardError => e
          error_msg = "Failed to localize menu ##{menu.id} to locale #{restaurant_locale.locale}: #{e.message}"
          Rails.logger.error("[LocalizeMenuService] #{error_msg}")
          stats[:errors] << error_msg
        end
      end

      Rails.logger.info("[LocalizeMenuService] Localized #{stats[:menus_processed]} menus to locale #{restaurant_locale.locale}")
      stats
    end

    # Core localization logic: Localize a single menu to a specific locale
    # Uses upsert pattern (idempotent - safe to run multiple times)
    #
    # @param menu [Menu] The menu to localize
    # @param restaurant_locale [Restaurantlocale] The locale to localize to
    # @return [Hash] Statistics about this specific localization
    def localize_menu_to_locale(menu, restaurant_locale)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0 }

      # Upsert menu locale
      menu_locale = Menulocale.find_or_initialize_by(
        menu_id: menu.id,
        locale: locale_code
      )

      was_new_record = menu_locale.new_record?

      menu_locale.assign_attributes(
        status: restaurant_locale.status,
        name: localize_text(menu.name, locale_code, is_default),
        description: localize_text(menu.description, locale_code, is_default)
      )

      if menu_locale.changed?
        menu_locale.save!
        if was_new_record
          stats[:menu_locales_created] += 1
        else
          stats[:menu_locales_updated] += 1
        end
      end

      # Localize all sections
      menu.menusections.find_each do |section|
        section_stats = localize_section_to_locale(section, restaurant_locale)
        stats[:section_locales_created] += section_stats[:section_locales_created]
        stats[:section_locales_updated] += section_stats[:section_locales_updated]
        stats[:item_locales_created] += section_stats[:item_locales_created]
        stats[:item_locales_updated] += section_stats[:item_locales_updated]
      end

      stats
    end

    private

    # Localize a menu section to a specific locale
    def localize_section_to_locale(section, restaurant_locale)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0 }

      # Upsert section locale
      section_locale = Menusectionlocale.find_or_initialize_by(
        menusection_id: section.id,
        locale: locale_code
      )

      was_new_record = section_locale.new_record?

      section_locale.assign_attributes(
        status: restaurant_locale.status,
        name: localize_text(section.name, locale_code, is_default),
        description: localize_text(section.description, locale_code, is_default)
      )

      if section_locale.changed?
        section_locale.save!
        if was_new_record
          stats[:section_locales_created] += 1
        else
          stats[:section_locales_updated] += 1
        end
      end

      # Localize all items in this section
      section.menuitems.find_each do |item|
        item_stats = localize_item_to_locale(item, restaurant_locale)
        stats[:item_locales_created] += item_stats[:item_locales_created]
        stats[:item_locales_updated] += item_stats[:item_locales_updated]
      end

      stats
    end

    # Localize a menu item to a specific locale
    def localize_item_to_locale(item, restaurant_locale)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { item_locales_created: 0, item_locales_updated: 0 }

      # Upsert item locale
      item_locale = Menuitemlocale.find_or_initialize_by(
        menuitem_id: item.id,
        locale: locale_code
      )

      was_new_record = item_locale.new_record?

      item_locale.assign_attributes(
        status: restaurant_locale.status,
        name: localize_text(item.name, locale_code, is_default),
        description: localize_text(item.description, locale_code, is_default)
      )

      if item_locale.changed?
        item_locale.save!
        if was_new_record
          stats[:item_locales_created] += 1
        else
          stats[:item_locales_updated] += 1
        end
      end

      stats
    end

    # Localize text: either copy (default locale) or translate (non-default locale)
    #
    # @param text [String] The text to localize
    # @param locale_code [String] The target locale code (e.g., 'IT', 'FR')
    # @param is_default [Boolean] Whether this is the default locale
    # @return [String] The localized text
    def localize_text(text, locale_code, is_default)
      return text if text.blank?
      return text if is_default

      translate_with_fallback(text, locale_code)
    end

    # Translate text with fallback to original on error
    # Includes retry logic with exponential backoff for rate limiting (429 errors)
    #
    # @param text [String] The text to translate
    # @param target_locale [String] The target locale code
    # @param source_locale [String] The source locale code (default: 'en')
    # @return [String] The translated text or original text on error
    def translate_with_fallback(text, target_locale, source_locale: 'en')
      return text if text.blank?

      max_retries = 3
      retry_count = 0
      base_delay = 1.0 # Start with 1 second

      begin
        result = DeeplApiService.translate(text, to: target_locale, from: source_locale)
        
        # Add small delay to prevent rate limiting (50ms between calls)
        sleep(0.05) unless Rails.env.test?
        
        result
      rescue StandardError => e
        # Check if it's a rate limit error (429)
        if e.message.include?('429') && retry_count < max_retries
          retry_count += 1
          delay = base_delay * (2 ** (retry_count - 1)) # Exponential backoff: 1s, 2s, 4s
          
          Rails.logger.warn("[LocalizeMenuService] Rate limit hit (429) for '#{text.truncate(50)}' to #{target_locale}. Retry #{retry_count}/#{max_retries} after #{delay}s")
          sleep(delay)
          retry
        end
        
        # For other errors or max retries exceeded, log and fallback
        Rails.logger.warn("[LocalizeMenuService] Translation failed for '#{text.truncate(50)}' to #{target_locale}: #{e.message}")
        text # Fallback to original text
      end
    end
  end
end
