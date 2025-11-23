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
    # @param force [Boolean] If true, re-translate all strings. If false, only translate missing localizations.
    # @return [Hash] Statistics about localization operations
    def localize_menu_to_all_locales(menu, force: false, &on_item)
      restaurant = menu.restaurant
      stats = { locales_processed: 0, menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0, 
                rate_limited_items: [], errors: [], }

      restaurant.restaurantlocales.active.find_each do |restaurant_locale|
        locale_stats = localize_menu_to_locale(menu, restaurant_locale, force: force, &on_item)
        stats[:locales_processed] += 1
        stats[:menu_locales_created] += locale_stats[:menu_locales_created]
        stats[:menu_locales_updated] += locale_stats[:menu_locales_updated]
        stats[:section_locales_created] += locale_stats[:section_locales_created]
        stats[:section_locales_updated] += locale_stats[:section_locales_updated]
        stats[:item_locales_created] += locale_stats[:item_locales_created]
        stats[:item_locales_updated] += locale_stats[:item_locales_updated]
        stats[:rate_limited_items].concat(locale_stats[:rate_limited_items]) if locale_stats[:rate_limited_items]
      rescue StandardError => e
        error_msg = "Failed to localize menu ##{menu.id} to locale #{restaurant_locale.locale}: #{e.message}"
        Rails.logger.error("[LocalizeMenuService] #{error_msg}")
        stats[:errors] << error_msg
      end

      Rails.logger.info("[LocalizeMenuService] Localized menu ##{menu.id} to #{stats[:locales_processed]} locales")
      
      # Queue rate-limited items for retry
      if stats[:rate_limited_items].any?
        Rails.logger.info("[LocalizeMenuService] Queueing #{stats[:rate_limited_items].count} rate-limited items for retry")
        safe_items = stats[:rate_limited_items].map { |h| h.stringify_keys }
        MenuLocalizationRetryJob.perform_in(5.minutes, safe_items)
      end
      
      stats
    end

    # Use Case 2: Localize all restaurant menus to a newly added locale
    # Called when a new restaurant locale is created
    #
    # @param restaurant [Restaurant] The restaurant whose menus to localize
    # @param restaurant_locale [Restaurantlocale] The new locale to localize to
    # @param force [Boolean] If true, re-translate all strings. If false, only translate missing localizations.
    # @return [Hash] Statistics about localization operations
    def localize_all_menus_to_locale(restaurant, restaurant_locale, force: false, &on_item)
      stats = { menus_processed: 0, menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0, 
                rate_limited_items: [], errors: [], }

      restaurant.menus.find_each do |menu|
        menu_stats = localize_menu_to_locale(menu, restaurant_locale, force: force, &on_item)
        stats[:menus_processed] += 1
        stats[:menu_locales_created] += menu_stats[:menu_locales_created]
        stats[:menu_locales_updated] += menu_stats[:menu_locales_updated]
        stats[:section_locales_created] += menu_stats[:section_locales_created]
        stats[:section_locales_updated] += menu_stats[:section_locales_updated]
        stats[:item_locales_created] += menu_stats[:item_locales_created]
        stats[:item_locales_updated] += menu_stats[:item_locales_updated]
        stats[:rate_limited_items].concat(menu_stats[:rate_limited_items]) if menu_stats[:rate_limited_items]
      rescue StandardError => e
        error_msg = "Failed to localize menu ##{menu.id} to locale #{restaurant_locale.locale}: #{e.message}"
        Rails.logger.error("[LocalizeMenuService] #{error_msg}")
        stats[:errors] << error_msg
      end

      Rails.logger.info("[LocalizeMenuService] Localized #{stats[:menus_processed]} menus to locale #{restaurant_locale.locale}")
      
      # Queue rate-limited items for retry
      if stats[:rate_limited_items].any?
        Rails.logger.info("[LocalizeMenuService] Queueing #{stats[:rate_limited_items].count} rate-limited items for retry")
        MenuLocalizationRetryJob.perform_in(5.minutes, stats[:rate_limited_items])
      end
      
      stats
    end

    # Core localization logic: Localize a single menu to a specific locale
    # Uses upsert pattern (idempotent - safe to run multiple times)
    #
    # @param menu [Menu] The menu to localize
    # @param restaurant_locale [Restaurantlocale] The locale to localize to
    # @param force [Boolean] If true, re-translate all strings. If false, only translate missing localizations.
    # @return [Hash] Statistics about this specific localization
    def localize_menu_to_locale(menu, restaurant_locale, force: false, &on_item)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { menu_locales_created: 0, menu_locales_updated: 0,
                section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0,
                rate_limited_items: [], }

      # Upsert menu locale
      menu_locale = Menulocale.find_or_initialize_by(
        menu_id: menu.id,
        locale: locale_code,
      )

      was_new_record = menu_locale.new_record?

      # Always compute localized text so that content changes get propagated.
      # This also allows us to count an update even if values remain the same (idempotent run).
      translation_result = localize_text_with_tracking(menu.name, locale_code, is_default)
      description_result = localize_text_with_tracking(menu.description, locale_code, is_default)

      menu_locale.assign_attributes(
        status: restaurant_locale.status,
        name: translation_result[:text],
        description: description_result[:text],
      )

      # Track rate-limited items
      if translation_result[:rate_limited]
        stats[:rate_limited_items] << { type: 'menu', id: menu.id, field: 'name', locale: locale_code, text: menu.name }
      end
      if description_result[:rate_limited]
        stats[:rate_limited_items] << { type: 'menu', id: menu.id, field: 'description', locale: locale_code, text: menu.description }
      end

      if was_new_record
        menu_locale.save!
        stats[:menu_locales_created] += 1
      else
        if menu_locale.changed?
          menu_locale.save!
        else
          # Touch to reflect a processed update even if attributes are identical
          menu_locale.touch if menu_locale.respond_to?(:touch)
        end
        stats[:menu_locales_updated] += 1
      end

      # Localize all sections
      menu.menusections.find_each do |section|
        section_stats = localize_section_to_locale(section, restaurant_locale, force: force, &on_item)
        stats[:section_locales_created] += section_stats[:section_locales_created]
        stats[:section_locales_updated] += section_stats[:section_locales_updated]
        stats[:item_locales_created] += section_stats[:item_locales_created]
        stats[:item_locales_updated] += section_stats[:item_locales_updated]
        stats[:rate_limited_items].concat(section_stats[:rate_limited_items]) if section_stats[:rate_limited_items]
      end

      stats
    end

    private

    # Localize a menu section to a specific locale
    def localize_section_to_locale(section, restaurant_locale, force: false, &on_item)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { section_locales_created: 0, section_locales_updated: 0,
                item_locales_created: 0, item_locales_updated: 0,
                rate_limited_items: [], }

      # Upsert section locale
      section_locale = Menusectionlocale.find_or_initialize_by(
        menusection_id: section.id,
        locale: locale_code,
      )

      was_new_record = section_locale.new_record?

      # Skip if already localized and force is false
      should_translate = force || was_new_record || section_locale.name.blank?
      
      if should_translate
        translation_result = localize_text_with_tracking(section.name, locale_code, is_default)
        description_result = localize_text_with_tracking(section.description, locale_code, is_default)
        
        section_locale.assign_attributes(
          status: restaurant_locale.status,
          name: translation_result[:text],
          description: description_result[:text],
        )
        
        # Track rate-limited items
        if translation_result[:rate_limited]
          stats[:rate_limited_items] << { type: 'section', id: section.id, field: 'name', locale: locale_code, text: section.name }
        end
        if description_result[:rate_limited]
          stats[:rate_limited_items] << { type: 'section', id: section.id, field: 'description', locale: locale_code, text: section.description }
        end
      end

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
        item_stats = localize_item_to_locale(item, restaurant_locale, force: force, &on_item)
        stats[:item_locales_created] += item_stats[:item_locales_created]
        stats[:item_locales_updated] += item_stats[:item_locales_updated]
        stats[:rate_limited_items].concat(item_stats[:rate_limited_items]) if item_stats[:rate_limited_items]
      end

      stats
    end

    # Localize a menu item to a specific locale
    def localize_item_to_locale(item, restaurant_locale, force: false, &on_item)
      locale_code = restaurant_locale.locale
      is_default = restaurant_locale.dfault
      stats = { item_locales_created: 0, item_locales_updated: 0, rate_limited_items: [] }

      # Upsert item locale
      item_locale = Menuitemlocale.find_or_initialize_by(
        menuitem_id: item.id,
        locale: locale_code,
      )

      was_new_record = item_locale.new_record?

      # Skip if already localized and force is false
      should_translate = force || was_new_record || item_locale.name.blank?
      
      if should_translate
        translation_result = localize_text_with_tracking(item.name, locale_code, is_default)
        description_result = localize_text_with_tracking(item.description, locale_code, is_default)
        
        item_locale.assign_attributes(
          status: restaurant_locale.status,
          name: translation_result[:text],
          description: description_result[:text],
        )
        
        # Track rate-limited items
        if translation_result[:rate_limited]
          stats[:rate_limited_items] << { type: 'item', id: item.id, field: 'name', locale: locale_code, text: item.name }
        end
        if description_result[:rate_limited]
          stats[:rate_limited_items] << { type: 'item', id: item.id, field: 'description', locale: locale_code, text: item.description }
        end
      end

      if item_locale.changed?
        item_locale.save!
        if was_new_record
          stats[:item_locales_created] += 1
        else
          stats[:item_locales_updated] += 1
        end
        # Notify progress callback
        if block_given?
          yield({
            item_id: item.id,
            item_name: item.name,
            locale: locale_code,
            translated_name: item_locale.name,
            translated_description: item_locale.description
          })
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
    
    # Localize text with rate limiting tracking
    # Returns a hash with translated text and rate limit status
    #
    # @param text [String] The text to localize
    # @param locale_code [String] The target locale code
    # @param is_default [Boolean] Whether this is the default locale
    # @return [Hash] { text: String, rate_limited: Boolean }
    def localize_text_with_tracking(text, locale_code, is_default)
      return { text: text, rate_limited: false } if text.blank?
      return { text: text, rate_limited: false } if is_default

      translate_with_rate_limit_tracking(text, locale_code)
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
          delay = base_delay * (2**(retry_count - 1)) # Exponential backoff: 1s, 2s, 4s

          Rails.logger.warn("[LocalizeMenuService] Rate limit hit (429) for '#{text.truncate(50)}' to #{target_locale}. Retry #{retry_count}/#{max_retries} after #{delay}s")
          sleep(delay)
          retry
        end

        # For other errors or max retries exceeded, log and fallback
        Rails.logger.warn("[LocalizeMenuService] Translation failed for '#{text.truncate(50)}' to #{target_locale}: #{e.message}")
        text # Fallback to original text
      end
    end
    
    # Translate text with rate limit tracking
    # Returns a hash indicating if translation was rate-limited
    #
    # @param text [String] The text to translate
    # @param target_locale [String] The target locale code
    # @param source_locale [String] The source locale code (default: 'en')
    # @return [Hash] { text: String, rate_limited: Boolean }
    def translate_with_rate_limit_tracking(text, target_locale, source_locale: 'en')
      return { text: text, rate_limited: false } if text.blank?

      max_retries = 2 # Reduced from 3 for faster failure
      retry_count = 0
      base_delay = 1.0

      begin
        result = DeeplApiService.translate(text, to: target_locale, from: source_locale)

        # Add small delay to prevent rate limiting (50ms between calls)
        sleep(0.05) unless Rails.env.test?

        { text: result, rate_limited: false }
      rescue StandardError => e
        # Check if it's a rate limit error (429)
        if e.message.include?('429') && retry_count < max_retries
          retry_count += 1
          delay = base_delay * (2**(retry_count - 1))

          Rails.logger.warn("[LocalizeMenuService] Rate limit hit (429) for '#{text.truncate(50)}' to #{target_locale}. Retry #{retry_count}/#{max_retries} after #{delay}s")
          sleep(delay)
          retry
        end

        # If still rate limited after retries, mark for later processing
        if e.message.include?('429')
          Rails.logger.warn("[LocalizeMenuService] Rate limit exceeded for '#{text.truncate(50)}' to #{target_locale}. Will retry later.")
          { text: text, rate_limited: true } # Keep original text, mark as rate-limited
        else
          # For other errors, log and use original text
          Rails.logger.warn("[LocalizeMenuService] Translation failed for '#{text.truncate(50)}' to #{target_locale}: #{e.message}")
          { text: text, rate_limited: false }
        end
      end
    end
  end
end
