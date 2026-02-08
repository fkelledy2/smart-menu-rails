class ProductEnrichmentRefreshJob
  include Sidekiq::Job

  sidekiq_options queue: 'low_priority', retry: 3

  # Refresh enrichments for products with missing or expired enrichment.
  # Uses the same logic as Menu::EnrichProductsJob (external provider when configured, otherwise OpenAI fallback).
  def perform(batch_size = 50)
    ids = product_ids_needing_refresh(limit: batch_size.to_i)
    return if ids.empty?

    ids.each do |product_id|
      product = Product.find_by(id: product_id)
      next unless product

      begin
        refresh_enrichment_for!(product)
      rescue StandardError => e
        Rails.logger.warn("[ProductEnrichmentRefreshJob] Failed for product ##{product.id}: #{e.class}: #{e.message}")
      end
    end
  end

  private

  def product_ids_needing_refresh(limit:)
    # Latest enrichment per product; refresh when missing OR expires_at in the past.
    # This is written to avoid expensive grouping; it intentionally limits work per run.
    expired_ids = ProductEnrichment
      .where('expires_at IS NOT NULL AND expires_at < ?', Time.current)
      .order(expires_at: :asc)
      .limit(limit)
      .pluck(:product_id)

    return expired_ids if expired_ids.any?

    # Missing enrichment
    Product
      .where.missing(:product_enrichments)
      .limit(limit)
      .pluck(:id)
  end

  def refresh_enrichment_for!(product)
    existing = ProductEnrichment.where(product_id: product.id).order(created_at: :desc).first
    if existing&.expires_at.present? && existing.expires_at > Time.current
      return existing
    end

    payload = nil
    source = nil
    external_id = nil

    if whisky_hunter_configured? && product.product_type == 'whiskey'
      client = WhiskyHunterClient.new
      resp = client.search_by_name(product.canonical_name)
      payload = {
        provider: 'whisky_hunter',
        raw: resp.parsed_response,
      }
      source = 'whisky_hunter'
      external_id = extract_external_id(resp.parsed_response)
    else
      payload = llm_enrich(product)
      source = 'openai'
    end

    ProductEnrichment.create!(
      product: product,
      source: source,
      external_id: external_id,
      payload_json: payload.is_a?(Hash) ? payload : { raw: payload },
      fetched_at: Time.current,
      expires_at: 30.days.from_now,
    )
  end

  def whisky_hunter_configured?
    ENV.fetch('WHISKY_HUNTER_BASE_URI', '').to_s.strip != ''
  end

  def extract_external_id(parsed_response)
    return nil unless parsed_response.is_a?(Hash)

    parsed_response['id'] || parsed_response.dig('data', 0, 'id') || parsed_response.dig('results', 0, 'id')
  end

  def llm_enrich(product)
    client = Rails.configuration.x.openai_client
    return fallback_payload(product) unless client

    system_msg = 'You are a beverage sommelier assistant. Return strict JSON only.'
    user_msg = {
      product_type: product.product_type,
      canonical_name: product.canonical_name,
      required_fields: {
        category: 'string',
        country: 'string',
        region: 'string',
        brand_story: 'string',
        production_notes: 'string',
        tasting_notes: {
          nose: 'string',
          palate: 'string',
          finish: 'string',
        },
        tags: ['string'],
        source_attribution: {
          brand_story: 'openai_generated',
          production_notes: 'openai_generated',
          tasting_notes: 'openai_generated',
        },
      },
    }.to_json

    params = {
      model: ENV.fetch('OPENAI_SOMMELIER_MODEL', 'gpt-4o-mini'),
      temperature: 0.2,
      messages: [
        { role: 'system', content: system_msg },
        { role: 'user', content: user_msg },
      ],
    }

    resp = client.chat(parameters: params)
    content = resp.dig('choices', 0, 'message', 'content').to_s.strip
    raise StandardError, 'Empty OpenAI response' if content == ''

    JSON.parse(content)
  rescue StandardError => e
    Rails.logger.warn("[ProductEnrichmentRefreshJob] OpenAI enrichment failed for '#{product.canonical_name}': #{e.class}: #{e.message}")
    fallback_payload(product)
  end

  def fallback_payload(product)
    {
      product_type: product.product_type,
      canonical_name: product.canonical_name,
      source_attribution: {
        note: 'fallback_no_enrichment',
      },
    }
  end
end
