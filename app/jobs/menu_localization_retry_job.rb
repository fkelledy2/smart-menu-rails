require 'sidekiq'

# Background job for retrying rate-limited menu localizations
# This job is automatically queued when MenuLocalizationJob encounters rate limits
# It attempts to translate items that were previously rate-limited
#
# Usage (automatic from LocalizeMenuService):
#   MenuLocalizationRetryJob.perform_in(5.minutes, rate_limited_items_array)
#
# rate_limited_items format:
#   [
#     { type: 'menu', id: 123, field: 'name', locale: 'it', text: 'Menu Title' },
#     { type: 'section', id: 456, field: 'description', locale: 'es', text: 'Section desc' },
#     { type: 'item', id: 789, field: 'name', locale: 'fr', text: 'Item name' }
#   ]
class MenuLocalizationRetryJob
  include Sidekiq::Worker

  sidekiq_options queue: 'low_priority', retry: 2

  # Process rate-limited translations
  #
  # @param rate_limited_items [Array<Hash>] Array of items to retry
  def perform(rate_limited_items)
    return if rate_limited_items.blank?

    Rails.logger.info("[MenuLocalizationRetryJob] Retrying #{rate_limited_items.count} rate-limited translations")

    stats = {
      processed: 0,
      successful: 0,
      still_rate_limited: [],
      errors: []
    }

    rate_limited_items.each do |item|
      begin
        retry_item_translation(item, stats)
        stats[:processed] += 1
      rescue StandardError => e
        error_msg = "Failed to retry #{item[:type]} ##{item[:id]} #{item[:field]}: #{e.message}"
        Rails.logger.error("[MenuLocalizationRetryJob] #{error_msg}")
        stats[:errors] << error_msg
      end
    end

    Rails.logger.info("[MenuLocalizationRetryJob] Completed: #{stats[:successful]} successful, #{stats[:still_rate_limited].count} still rate-limited, #{stats[:errors].count} errors")

    # If there are still rate-limited items, queue another retry after longer delay
    if stats[:still_rate_limited].any?
      Rails.logger.info("[MenuLocalizationRetryJob] Queueing #{stats[:still_rate_limited].count} items for another retry in 15 minutes")
      MenuLocalizationRetryJob.perform_in(15.minutes, stats[:still_rate_limited])
    end

    stats
  end

  private

  # Retry translating a single item
  def retry_item_translation(item, stats)
    locale_code = item[:locale]
    text = item[:text]
    
    return if text.blank?

    # Attempt translation with rate limit tracking
    result = translate_with_tracking(text, locale_code)

    if result[:rate_limited]
      # Still rate-limited, queue for later
      stats[:still_rate_limited] << item
      Rails.logger.warn("[MenuLocalizationRetryJob] #{item[:type]} ##{item[:id]} #{item[:field]} still rate-limited")
    elsif result[:text] != text
      # Successfully translated, save to database
      save_translation(item[:type], item[:id], item[:field], locale_code, result[:text])
      stats[:successful] += 1
      Rails.logger.info("[MenuLocalizationRetryJob] Successfully translated #{item[:type]} ##{item[:id]} #{item[:field]} to #{locale_code}")
    else
      # Translation returned original text (non-rate-limit error)
      stats[:successful] += 1 # Count as processed even if unchanged
      Rails.logger.warn("[MenuLocalizationRetryJob] Translation unchanged for #{item[:type]} ##{item[:id]} #{item[:field]}")
    end
  end

  # Translate text with rate limit tracking
  def translate_with_tracking(text, target_locale, source_locale: 'en')
    return { text: text, rate_limited: false } if text.blank?

    max_retries = 2
    retry_count = 0
    base_delay = 2.0 # Start with 2 seconds for retries

    begin
      result = DeeplApiService.translate(text, to: target_locale, from: source_locale)
      
      # Add delay to prevent rate limiting
      sleep(0.1) unless Rails.env.test?
      
      { text: result, rate_limited: false }
    rescue StandardError => e
      # Check if it's a rate limit error (429)
      if e.message.include?('429') && retry_count < max_retries
        retry_count += 1
        delay = base_delay * (2**(retry_count - 1)) # Exponential backoff: 2s, 4s
        
        Rails.logger.warn("[MenuLocalizationRetryJob] Rate limit hit for '#{text.truncate(50)}' to #{target_locale}. Retry #{retry_count}/#{max_retries} after #{delay}s")
        sleep(delay)
        retry
      end
      
      # If still rate limited, mark for later retry
      if e.message.include?('429')
        Rails.logger.warn("[MenuLocalizationRetryJob] Rate limit exceeded for '#{text.truncate(50)}' to #{target_locale}. Will retry later.")
        { text: text, rate_limited: true }
      else
        # For other errors, log and use original text
        Rails.logger.warn("[MenuLocalizationRetryJob] Translation failed for '#{text.truncate(50)}' to #{target_locale}: #{e.message}")
        { text: text, rate_limited: false }
      end
    end
  end

  # Save translated text to the appropriate locale record
  def save_translation(type, id, field, locale_code, translated_text)
    case type
    when 'menu'
      save_menu_translation(id, field, locale_code, translated_text)
    when 'section'
      save_section_translation(id, field, locale_code, translated_text)
    when 'item'
      save_item_translation(id, field, locale_code, translated_text)
    else
      raise ArgumentError, "Unknown type: #{type}"
    end
  end

  def save_menu_translation(menu_id, field, locale_code, text)
    menu_locale = Menulocale.find_or_initialize_by(menu_id: menu_id, locale: locale_code)
    menu_locale.update!(field => text)
  end

  def save_section_translation(section_id, field, locale_code, text)
    section_locale = Menusectionlocale.find_or_initialize_by(menusection_id: section_id, locale: locale_code)
    section_locale.update!(field => text)
  end

  def save_item_translation(item_id, field, locale_code, text)
    item_locale = Menuitemlocale.find_or_initialize_by(menuitem_id: item_id, locale: locale_code)
    item_locale.update!(field => text)
  end
end
