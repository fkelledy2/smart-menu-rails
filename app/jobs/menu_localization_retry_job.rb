require 'sidekiq'

# Background job for retrying rate-limited menu localizations.
# Enqueued by LocalizeMenuService when DeepL returns 429.
#
# Backoff schedule (attempt number passed as second argument):
#   attempt 1 → 60s,  attempt 2 → 5min,  attempt 3 → 30min,  attempt 4+ → 1hr
#
# When a 429 is hit mid-batch, remaining unprocessed items are re-queued at
# the next backoff tier rather than retrying the entire job from scratch.
class MenuLocalizationRetryJob
  include Sidekiq::Worker

  sidekiq_options queue: 'low_priority', retry: 0

  BACKOFF_DELAYS = [60, 300, 1800, 3600].freeze # seconds: 1min, 5min, 30min, 1hr

  def perform(rate_limited_items, attempt = 1)
    return if rate_limited_items.blank?

    Rails.logger.info("[MenuLocalizationRetryJob] Attempt #{attempt}: retrying #{rate_limited_items.count} rate-limited translations")

    stats = { processed: 0, successful: 0, still_rate_limited: [], errors: [] }
    hit_rate_limit = false

    rate_limited_items.each do |item|
      if hit_rate_limit
        # Circuit breaker tripped — queue everything remaining without calling DeepL
        stats[:still_rate_limited] << item
        next
      end

      result = retry_item_translation(item, stats)
      stats[:processed] += 1

      if result == :rate_limited
        hit_rate_limit = true
        stats[:still_rate_limited] << item
      end
    rescue StandardError => e
      stats[:errors] << "#{item['type']} ##{item['id']} #{item['field']}: #{e.message}"
      Rails.logger.error("[MenuLocalizationRetryJob] #{stats[:errors].last}")
    end

    Rails.logger.info("[MenuLocalizationRetryJob] Attempt #{attempt} complete: #{stats[:successful]} translated, #{stats[:still_rate_limited].count} still rate-limited, #{stats[:errors].count} errors")

    reschedule_if_needed(stats[:still_rate_limited], attempt)
  end

  private

  def retry_item_translation(item, stats)
    locale_code = item['locale'] || item[:locale]
    text        = item['text']   || item[:text]
    item_type   = item['type']   || item[:type]
    item_id     = item['id']     || item[:id]
    item_field  = item['field']  || item[:field]

    return if text.blank?

    unless DeeplApiService.configured?
      log_deepl_missing_api_key_once
      return
    end

    translated = DeeplApiService.translate(text, to: locale_code, from: 'en')

    # Small inter-call delay to stay within DeepL's burst limit
    sleep(0.1) unless Rails.env.test?

    save_translation(item_type, item_id, item_field, locale_code, translated)
    stats[:successful] += 1
    Rails.logger.info("[MenuLocalizationRetryJob] Translated #{item_type} ##{item_id} #{item_field} → #{locale_code}")

    :success
  rescue StandardError => e
    if e.message.include?('429')
      Rails.logger.warn("[MenuLocalizationRetryJob] Rate limit hit for #{item_type} ##{item_id} #{item_field}. Stopping batch.")
      :rate_limited
    else
      Rails.logger.warn("[MenuLocalizationRetryJob] Translation failed for #{item_type} ##{item_id}: #{e.message}")
      :error
    end
  end

  def reschedule_if_needed(items, current_attempt)
    return if items.blank?

    next_attempt = current_attempt + 1
    delay = BACKOFF_DELAYS[[current_attempt - 1, BACKOFF_DELAYS.length - 1].min]

    Rails.logger.info("[MenuLocalizationRetryJob] Scheduling #{items.count} items for retry in #{delay}s (will be attempt #{next_attempt})")
    MenuLocalizationRetryJob.perform_in(delay.seconds, items, next_attempt)
  end

  def save_translation(type, id, field, locale_code, translated_text)
    case type
    when 'menu'
      Menulocale.find_or_initialize_by(menu_id: id, locale: locale_code).tap do |r|
        r.update!(field => translated_text)
      end
    when 'section'
      Menusectionlocale.find_or_initialize_by(menusection_id: id, locale: locale_code).tap do |r|
        r.update!(field => translated_text)
      end
    when 'item'
      Menuitemlocale.find_or_initialize_by(menuitem_id: id, locale: locale_code).tap do |r|
        r.update!(field => translated_text)
      end
    else
      raise ArgumentError, "Unknown type: #{type}"
    end
  end

  def log_deepl_missing_api_key_once
    return if @deepl_missing_api_key_logged

    @deepl_missing_api_key_logged = true
    Rails.logger.warn('[MenuLocalizationRetryJob] DeepL disabled (DEEPL_API_KEY missing). Skipping translation retries.')
  end
end
