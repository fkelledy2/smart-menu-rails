class Menu::EnrichProductsJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(pipeline_run_id, trigger = nil)
    run = BeveragePipelineRun.find_by(id: pipeline_run_id)
    return unless run

    run.update!(current_step: 'enrich_products')

    menu = run.menu

    product_ids = MenuItemProductLink
      .joins(menuitem: { menusection: :menu })
      .where(menus: { id: menu.id })
      .distinct
      .pluck(:product_id)

    Product.where(id: product_ids).find_each do |product|
      ensure_product_enrichment!(product)
    rescue StandardError => e
      Rails.logger.warn("[EnrichProductsJob] Enrichment failed for product ##{product.id}: #{e.class}: #{e.message}")
    end

    Menu::GeneratePairingsJob.perform_async(run.id, trigger)
  rescue StandardError => e
    run&.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}")
    raise
  end

  private

  def ensure_product_enrichment!(product)
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
    Rails.logger.warn("[EnrichProductsJob] OpenAI enrichment failed for '#{product.canonical_name}': #{e.class}: #{e.message}")
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
